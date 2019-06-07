#!/usr/bin/env python3
# 
#       SapMonitor payload deployed on collector VM
#
#       License:        GNU General Public License (GPL)
#       (c) 2019        Microsoft Corp.
#
import pyhdb
import requests, json
import sys, argparse
import datetime, decimal
import hashlib, hmac, base64
import logging, http.client as http_client

###############################################################################

class SapHana:
   """
   Provide access to a HANA Database (HDB) instance
   """
   connection = None
   cursor     = None

   def __init__(self, host = None, port = None, user = None, password = None, hanaDetails = None):
      if hanaDetails:
         self.host     = hanaDetails["HanaHostname"]
         self.port     = hanaDetails["HanaDbSqlPort"]
         self.user     = hanaDetails["HanaDbUsername"]
         self.password = hanaDetails["HanaDbPassword"]
      else:
         self.host     = host
         self.port     = port
         self.user     = user
         self.password = password

   def connect(self):
      """
      Connect to a HDB instance
      """
      self.connection = pyhdb.connect(
         host = self.host,
         port = self.port,
         user = self.user,
         password = self.password,
         )
      self.cursor = self.connection.cursor()

   def runQuery(self, sql):
      """
      Execute a SQL query
      """
      self.cursor.execute(sql)
      colIndex = {col[0] : idx for idx, col in enumerate(self.cursor.description)}
      return colIndex, self.cursor.fetchall()

   def getLoadHistory(self, fromTimestamp, untilTimestamp = None):
      """
      Get infrastructure utilization via HANA Load History
      """
      sqlFrom  = "'%s'" % fromTimestamp.strftime("%Y-%m-%d %H:%M:%S.%f")
      sqlUntil = "'%s'" % untilTimestamp.strftime("%Y-%m-%d %H:%M:%S.%f") if untilTimestamp else "NOW()"
      sql      = """
SELECT
h.TIME AS SERVER_TIMESTAMP,
h.HOST AS HOST,
'HOST' AS SCOPE,
MAP(h.CPU, null, -1 , -1, -1, ROUND(100 * h.CPU / 1) / 100) AS CPU,
MAP(h.MEMORY_RESIDENT, null, -1 , -1, -1, ROUND(100 * h.MEMORY_RESIDENT / 1048576) / 100) AS MEMORY_RESIDENT,
MAP(h.MEMORY_TOTAL_RESIDENT, null, -1 , -1, -1, ROUND(100 * h.MEMORY_TOTAL_RESIDENT / 1048576) / 100) AS MEMORY_TOTAL_RESIDENT,
MAP(h.MEMORY_SIZE, null, -1 , -1, -1, ROUND(100 * h.MEMORY_SIZE / 1048576) / 100) AS MEMORY_SIZE,
MAP(h.MEMORY_USED, null, -1 , -1, -1, ROUND(100 * h.MEMORY_USED / 1048576) / 100) AS MEMORY_USED,
MAP(h.MEMORY_ALLOCATION_LIMIT, null, -1 , -1, -1, ROUND(100 * h.MEMORY_ALLOCATION_LIMIT / 1048576) / 100) AS MEMORY_ALLOCATION_LIMIT,
MAP(h.DISK_USED, null, -1 , -1, -1, ROUND(100 * h.DISK_USED / 1073741824) / 100) AS DISK_USED,
MAP(h.DISK_SIZE, null, -1 , -1, -1, ROUND(100 * h.DISK_SIZE / 1073741824) / 100) AS DISK_SIZE,
MAP(lag(h.TIME) OVER (order by h.host, h.time) , null , -1,  MAP(SUBSTRING(cast (h.NETWORK_IN as VARCHAR),0,1) ,'-',-1, 'n',-1,  round( 10000000*( 100 * h.NETWORK_IN / (NANO100_BETWEEN(lag(h.time) OVER (order by h.host, h.time),h.time) )) / 1048576) / 100)) AS NETWORK_IN,
MAP(lag(h.TIME) OVER (order by h.host, h.time) , null , -1, MAP(SUBSTRING(cast (h.NETWORK_OUT as VARCHAR),0,1) ,'-',-1, 'n',-1,  round( 10000000*( 100 * h.NETWORK_OUT / (NANO100_BETWEEN(lag(h.time) OVER (order by h.host, h.time),h.time) )) / 1048576) / 100)) AS NETWORK_OUT
FROM SYS.M_LOAD_HISTORY_HOST h 
WHERE h.TIME BETWEEN %s AND %s ORDER BY h.TIME ASC
""" % (sqlFrom, sqlUntil)
      return self.runQuery(sql)

###############################################################################

class REST:
   """
   Provide access to a REST endpoint
   """
   @staticmethod
   def sendRequest(endpoint, method = requests.get, params = {}, headers = {}, timeout = 5, data = None, debug = False):
      if debug:
         http_client.HTTPConnection.debuglevel = 1
         logging.basicConfig()
         logging.getLogger().setLevel(logging.DEBUG)
         requests_log = logging.getLogger("requests.packages.urllib3")
         requests_log.setLevel(logging.DEBUG)
         requests_log.propagate = True
      response = method(
         endpoint,
         params  = params,
         headers = headers,
         timeout = timeout,
         data    = data,
         )
      if response.status_code == requests.codes.ok:
         contentType = response.headers.get("content-type")
         if contentType and contentType.find("json") >= 0:
            return json.loads(response.content.decode("utf-8"))
         else:
            return response.content
      else:
         print(response.content) # poor man's logging
         response.raise_for_status()

###############################################################################

class AzureInstanceMetadataService:
   """
   Provide access to the Azure Instance Metadata Service (IMS) inside the VM
   """
   uri     = "http://169.254.169.254/metadata"
   params  = {"api-version": "2018-02-01"}
   headers = {"Metadata": "true"}

   @staticmethod
   def _sendRequest(endpoint, params = {}, headers = {}):
      params.update(AzureInstanceMetadataService.params)
      headers.update(AzureInstanceMetadataService.headers)
      return REST.sendRequest(
         "%s/%s" % (AzureInstanceMetadataService.uri, endpoint),
         params  = params,
         headers = headers,
         )

   @staticmethod
   def getComputeInstance():
      """
      Get the compute instance for the current VM via IMS
      """
      return AzureInstanceMetadataService._sendRequest(
         "instance",
         )["compute"]

   @staticmethod
   def getAuthToken(resource):
      """
      Get an authentication token via IMS
      """
      return AzureInstanceMetadataService._sendRequest(
         "identity/oauth2/token",
         params = {"resource": resource}
         )["access_token"]

###############################################################################

class AzureKeyVault:
   """
   Provide access to an Azure KeyVault instance
   """
   params  = {"api-version": "7.0"}

   def __init__(self, keyvaultName):
      self.uri     = "https://%s.vault.azure.net" % keyvaultName
      self.token   = AzureInstanceMetadataService.getAuthToken("https://vault.azure.net")
      self.headers = {
         "Authorization": "Bearer %s" % self.token,
         "Content-Type":  "application/json"
         }

   def _sendRequest(self, endpoint, method = requests.get, data = None):
      """
      Easy access to KeyVault REST endpoints
      """
      return REST.sendRequest(
         endpoint,
         method  = method,
         params  = self.params,
         headers = self.headers,
         data    = data,
         )["value"]

   def setSecret(self, secretName, secretValue):
      """
      Set a secret in the KeyVault
      """
      return self._sendRequest(
         "%s/secrets/%s" % (self.uri, secretName),
         method = requests.put,
         data   = json.dumps({"value": secretValue})
         ) == secretValue

   def getSecret(self, secretId):
      """
      Get the current version of a specific secret in the KeyVault
      """
      return self._sendRequest(secretId)

   def getCurrentSecrets(self):
      """
      Get the current versions of all secrets inside the customer KeyVault
      """
      secrets = {}
      kvSecrets = self._sendRequest("%s/secrets" % self.uri)
      if not kvSecrets:
         return secrets
      for k in kvSecrets:
            id = k["id"].split("/")[-1]
            secrets[id] = self.getSecret(k["id"])
      return secrets

###############################################################################

class AzureLogAnalytics:
   """
   Provide access to an Azure Log Analytics WOrkspace
   """
   def __init__(self, workspaceId, sharedKey):
      self.workspaceId = workspaceId
      self.sharedKey   = sharedKey
      self.uri         = "https://%s.ods.opinsights.azure.com/api/logs?api-version=2016-04-01" % workspaceId

   def ingest(self, logType, jsonData):
      """
      Ingest JSON payload as custom log to Log Analytics.
      """
      def buildSig(content, timestamp):
         stringHash  = """POST
%d
application/json
x-ms-date:%s
/api/logs""" % (len(content), timestamp)
         bytesHash   = bytes(stringHash, encoding="utf-8")
         decodedKey  = base64.b64decode(self.sharedKey)
         encodedHash = base64.b64encode(hmac.new(
            decodedKey,
            bytesHash,
            digestmod=hashlib.sha256).digest()
         )
         stringHash  = encodedHash.decode("utf-8")
         return "SharedKey %s:%s" % (self.workspaceId, stringHash)

      timestamp   = datetime.datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")
      headers = {
         "content-type":  "application/json",
         "Authorization": buildSig(jsonData, timestamp),
         "Log-Type":      logType,
         "x-ms-date":     timestamp,
      }
      return REST.sendRequest(
         self.uri,
         method  = requests.post,
         headers = headers,
         data    = jsonData,
         )

###############################################################################

class _Context:
   """
   Internal context handler
   """
   hanaInstances = []

   def __init__(self):
      self.vmInstance = AzureInstanceMetadataService.getComputeInstance()
      vmTags          = dict(map(lambda s : s.split(':'), self.vmInstance["tags"].split(";")))
      self.sapmonId   = vmTags["SapMonId"]
      self.azKv       = AzureKeyVault("sapmon-%s" % self.sapmonId)

   def parseSecrets(self):
      """
      Read secrets from customer KeyVault and store credentials in context.
      """
      def sliceDict(d, s):
         return {k: v for k, v in iter(d.items()) if k.startswith(s)}
      secrets = self.azKv.getCurrentSecrets()

      # extract HANA instance(s) from secrets
      hanaSecrets = sliceDict(secrets, "SapHana-")
      for h in hanaSecrets.keys():
         hanaDetails  = json.loads(hanaSecrets[h])
         hanaInstance = SapHana(hanaDetails = hanaDetails)
         self.hanaInstances.append(hanaInstance)

      # extract Log Analytics credentials from secrets
      laSecret  = json.loads(secrets["AzureLogAnalytics"])
      self.azLa = AzureLogAnalytics(
         laSecret["LogAnalyticsWorkspaceId"],
         laSecret["LogAnalyticsSharedKey"]
         )

###############################################################################

class _JsonEncoder(json.JSONEncoder):
   """
   Helper class to serialize datetime and Decimal objects into JSON
   """
   def default(self, o):
      if isinstance(o, decimal.Decimal):
         return float(o)
      elif isinstance(o, (datetime.datetime, datetime.date)):
         return o.isoformat()
      return super(_JsonEncoder, self).default(o)

###############################################################################

def init(args):
   """
   Store credentials in the customer KeyVault.
   (To be executed as custom script upon initial deployment of collector VM.)
   """
   # Credentials (provided by user) to the existing HANA Dinstance
   hanaSecretName  = "SapHana-%s" % args.HanaDbName
   hanaSecretValue = json.dumps({
      "HanaHostname":   args.HanaHostname,
      "HanaDbName":     args.HanaDbName,
      "HanaDbUsername": args.HanaDbUsername,
      "HanaDbPassword": args.HanaDbPassword,
      "HanaDbSqlPort":  args.HanaDbSqlPort,
      })
   ctx.azKv.setSecret(hanaSecretName, hanaSecretValue)

   # Credentials (created by HanaRP) to the newly created Log Analytics Workspace
   laSecretName  = "AzureLogAnalytics"
   laSecretValue = json.dumps({
      "LogAnalyticsWorkspaceId": args.LogAnalyticsWorkspaceId,
      "LogAnalyticsSharedKey":   args.LogAnalyticsSharedKey,
      })
   ctx.azKv.setSecret(laSecretName, laSecretValue)

def monitor(args):
   """
   Actual SAP Monitor payload:
   - Obtain credentials from KeyVault secrets
   - For each DB tenant of the monitored HANA instance:
     - Connect to DB tenant via SQL
     - Execute monitoring statements
     - Emit metrics as custom log to Azure Log Analytics
   (To be executed as cronjob after all resources are deployed.)
   """
   ctx.parseSecrets()
   for h in ctx.hanaInstances:
      h.connect()
      fromTimestamp  = datetime.datetime.now() - datetime.timedelta(minutes=1)
      colIndex, resultRows = h.getLoadHistory(fromTimestamp)
      logData = []
      for r in resultRows:
         logItem = {}
         for c in colIndex.keys():
            logItem[c] = r[colIndex[c]]
         logData.append(logItem)
      jsonData = json.dumps(logData, sort_keys=True, indent=4, cls=_JsonEncoder)
      ctx.azLa.ingest("SapHana_Infra", jsonData)
      
def main():
   parser     = argparse.ArgumentParser(description="SAP on Azure Monitor Payload")
   subparsers = parser.add_subparsers(dest="command", help="main functions")
   subparsers.required = True
   initparser = subparsers.add_parser("init", help="Initialize client KeyVault with SAP credentials")
   initparser.set_defaults(func=init)
   initparser.add_argument("HanaHostname", type=str, help="Hostname of the HDB to be monitored")
   initparser.add_argument("HanaDbName", type=str, help="Name of the tenant DB (empty if not MDC)")
   initparser.add_argument("HanaDbUsername", type=str, help="DB username to connect to the HDB tenant")
   initparser.add_argument("HanaDbPassword", type=str, help="DB user password to connect to the HDB tenant")
   initparser.add_argument("HanaDbSqlPort", type=int, help="SQL port of the tenant DB")
   initparser.add_argument("LogAnalyticsWorkspaceId", type=str, help="Workspace ID (customer ID) of the Log Analytics Workspace")
   initparser.add_argument("LogAnalyticsSharedKey", type=str, help="Shared key (primary) of the Log Analytics Workspace")
   monparser  = subparsers.add_parser("monitor", help="Execute the monitoring payload")
   monparser.set_defaults(func=monitor)
   args       = parser.parse_args()
   args.func(args)

ctx = _Context()
if __name__ == "__main__":
   main()


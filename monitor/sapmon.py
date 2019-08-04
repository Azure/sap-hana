#!/usr/bin/env python3
# 
#       SapMonitor payload deployed on collector VM
#
#       License:        GNU General Public License (GPL)
#       (c) 2019        Microsoft Corp.
#
import pyhdb
from datetime import datetime, timedelta, date
import http.client as http_client
import requests, json
import os, sys, argparse
import decimal
import hashlib, hmac, base64
import logging, logging.config
import hashlib
import re

###############################################################################

PAYLOAD_VERSION              = "0.4.2"
PAYLOAD_DIRECTORY            = os.path.dirname(os.path.realpath(__file__))
STATE_FILE                   = "%s/sapmon.state" % PAYLOAD_DIRECTORY
INITIAL_LOADHISTORY_TIMESPAN = -(60 * 1)
TIME_FORMAT_HANA             = "%Y-%m-%d %H:%M:%S.%f"
TIME_FORMAT_LOG_ANALYTICS    = "%a, %d %b %Y %H:%M:%S GMT"
TIMEOUT_HANA                 = 5
DEFAULT_CONSOLE_LOG_LEVEL    = logging.INFO
DEFAULT_FILE_LOG_LEVEL       = logging.INFO
LOG_FILENAME                 = "%s/sapmon.log" % PAYLOAD_DIRECTORY
KEYVAULT_NAMING_CONVENTIONS  = ["sapmon%s", "sapmon-kv-%s"]

###############################################################################

LOG_CONFIG = {
   "version": 1,
   "disable_existing_loggers": True,
   "formatters": {
      "detailed": {
         "format": "[%(process)d] %(asctime)s %(levelname).1s %(funcName)s:%(lineno)d %(message)s",
      },
      "simple": {
         "format": "%(levelname)-8s %(message)s",
      }
   },
   "handlers": {
      "console": {
         "class": "logging.StreamHandler",
         "formatter": "simple",
         "level": DEFAULT_CONSOLE_LOG_LEVEL,
      },
      "file": {
         "class": "logging.handlers.RotatingFileHandler",
         "formatter": "detailed",
         "level": DEFAULT_FILE_LOG_LEVEL,
         "filename": LOG_FILENAME,
         "maxBytes": 10000000,
         "backupCount": 10,
      },
   },
   "root": {
      "level": logging.DEBUG,
      "handlers": ["console", "file"],
   }
}

###############################################################################

ERROR_GETTING_AUTH_TOKEN      = 10
ERROR_SETTING_KEYVAULT_SECRET = 20
ERROR_KEYVAULT_NOT_FOUND      = 21
ERROR_HANA_CONNECTION         = 30

###############################################################################

class SapHana:
   """
   Provide access to a HANA Database (HDB) instance
   """
   connection = None
   cursor     = None

   def __init__(self, host = None, port = None, user = None, password = None, hanaDetails = None):
      logger.info("initializing HANA instance")
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
      self.connection = pyhdb.Connection(
         host = self.host,
         port = self.port,
         user = self.user,
         password = self.password,
         timeout = TIMEOUT_HANA,
         )
      self.connection.connect()
      self.cursor = self.connection.cursor()

   def disconnect(self):
      """
      Close an open HDB connection
      """
      self.connection.close()

   def runQuery(self, sql):
      """
      Execute a SQL query
      """
      self.cursor.execute(sql)
      colIndex = {col[0] : idx for idx, col in enumerate(self.cursor.description)}
      return colIndex, self.cursor.fetchall()

   # TODO(tniek): Refactor monitoring into Query class
   def getLoadHistory(self, fromTimestamp):
      """
      Get infrastructure utilization via HANA Load History
      """
      logger.info("getting HANA Load History")
      if not fromTimestamp:
         sqlFrom = "h.TIME > ADD_SECONDS(NOW(), %d)" % INITIAL_LOADHISTORY_TIMESPAN
      else:
         sqlFrom = "ADD_SECONDS(h.TIME, i.VALUE*(-1)) > '%s'" % fromTimestamp.strftime(TIME_FORMAT_HANA)
      logger.debug("sqlFrom=%s" % sqlFrom)
      sql = """
SELECT
h.TIME AS _SERVER_TIMESTAMP,
i.VALUE AS _SERVER_UTC_OFFSET,
ADD_SECONDS(h.TIME, i.VALUE*(-1)) AS UTC_TIMESTAMP,
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
FROM SYS.M_LOAD_HISTORY_HOST h, SYS.M_HOST_INFORMATION i
WHERE %s
AND h.HOST = i.HOST AND UPPER(i.KEY) = 'TIMEZONE_OFFSET'
ORDER BY h.TIME ASC
""" % sqlFrom
      result = None
      try:
         result = self.runQuery(sql)
      except Exception as e:
         logger.error("could not get HANA Load History (%s)" % e)
      return result

   def getHostConfig(self):
      """
      Get HANA host configuration
      """
      logger.info("getting HANA Host Config")
      result = None
      sql = "SELECT * FROM SYS.M_LANDSCAPE_HOST_CONFIGURATION"
      try:
         result = self.runQuery(sql)
      except Exception as e:
         logger.error("could not get HANA Host Config (%s)" % e)
      return result

   def getNewResultHash(self, query, resultRows):
      """
      Compute hash of a specific query result and return it only if it's different from the previous one
      """
      logger.info("comparing query result with last execution")
      resultHash = None
      if len(resultRows) == 0:
         logger.info("result is empty")
      else:
         try:
            resultHash = hashlib.md5(str(resultRows).encode("utf-8")).hexdigest()
            logger.debug("resultHash=%s" % resultHash)
         except Exception as e:
            logger.error("could not calculate result hash (%s)" % e)
         if query not in ctx.lastResultHashes:
            logger.info("query has not been executed before")
         else:
            if ctx.lastResultHashes[query] == resultHash:
               logger.info("result is identical to last execution")
               resultHash = None
            else:
               logger.info("result has changed from last execution")
      return resultHash   

   def convertIntoJson(self, colIndex, resultRows):
      """
      Convert a query result into a JSON-formatted string (as required by Log Analytics)
      """
      logData = []
      for r in resultRows:
         logItem = {}
         for c in colIndex.keys():
            if c.startswith("_"): # remove internal fields
               continue
            logItem[c] = r[colIndex[c]]
         jsonData = json.dumps(logItem, sort_keys=True, indent=4, cls=_JsonEncoder)
         logData.append(logItem)
      return json.dumps(logData, sort_keys=True, indent=4, cls=_JsonEncoder)

###############################################################################

class REST:
   """
   Provide access to a REST endpoint
   """
   @staticmethod
   # TODO: improve error handling (include HTTP status together with response)
   def sendRequest(endpoint, method = requests.get, params = {}, headers = {}, timeout = 5, data = None, debug = False):
      if debug:
         http_client.HTTPConnection.debuglevel = 1
         logging.basicConfig()
         logging.getLogger().setLevel(logging.DEBUG)
         requests_log = logging.getLogger("requests.packages.urllib3")
         requests_log.setLevel(logging.DEBUG)
         requests_log.propagate = True
      try:
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
      except Exception as e:
         logger.error("could not send HTTP request (%s)" % e)
         return None

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
   def getComputeInstance(operation):
      """
      Get the compute instance for the current VM via IMS
      """
      logger.info("getting compute instance")      
      computeInstance = None
      try:
         computeInstance = AzureInstanceMetadataService._sendRequest(
            "instance",
            headers = {"User-Agent": "SAP Monitor/%s (%s)" % (PAYLOAD_VERSION, operation)}
            )["compute"]
         logger.debug("computeInstance=%s" % computeInstance)
      except Exception as e:
         logging.error("could not obtain instance metadata (%s)" % e)
      return computeInstance

   @staticmethod
   def getAuthToken(resource, msiClientId = None):
      """
      Get an authentication token via IMDS
      """
      logger.info("getting auth token for resource=%s%s" % (resource, ", msiClientId=%s" % msiClientId if msiClientId else ""))
      authToken = None
      try:
         authToken = AzureInstanceMetadataService._sendRequest(
            "identity/oauth2/token",
            params = {"resource": resource, "client_id": msiClientId}
            )["access_token"]
      except Exception as e:
         logger.critical("could not get auth token (%s)" % e)
         sys.exit(ERROR_GETTING_AUTH_TOKEN)
      return authToken

###############################################################################

class AzureKeyVault:
   """
   Provide access to an Azure KeyVault instance
   """
   params  = {"api-version": "7.0"}

   def __init__(self, kvName, msiClientId = None):
      logger.info("initializing KeyVault %s" % kvName)
      self.uri     = "https://%s.vault.azure.net" % kvName
      self.token   = AzureInstanceMetadataService.getAuthToken("https://vault.azure.net", msiClientId)
      self.headers = {
         "Authorization": "Bearer %s" % self.token,
         "Content-Type":  "application/json"
         }

   def _sendRequest(self, endpoint, method = requests.get, data = None):
      """
      Easy access to KeyVault REST endpoints
      """
      response = REST.sendRequest(
         endpoint,
         method  = method,
         params  = self.params,
         headers = self.headers,
         data    = data,
         )
      if response and "value" in response:
         return response["value"]
      return None

   def setSecret(self, secretName, secretValue):
      """
      Set a secret in the KeyVault
      """
      logger.info("setting KeyVault secret for secretName=%s" % secretName)
      success = False
      try:
         success = self._sendRequest(
            "%s/secrets/%s" % (self.uri, secretName),
            method = requests.put,
            data   = json.dumps({"value": secretValue})
            ) == secretValue
      except Exception as e:
         logger.critical("could not set KeyVault secret (%s)" % e)
         sys.exit(ERROR_SETTING_KEYVAULT_SECRET)
      return success

   def getSecret(self, secretId):
      """
      Get the current version of a specific secret in the KeyVault
      """
      logger.info("getting KeyVault secret for secretId=%s" % secretId)
      secret = None
      try:
         secret = self._sendRequest(secretId)
      except Exception as e:
         logger.error("could not get KeyVault secret for secretId=%s (%s)" % (secretId, e))
      return secret

   def getCurrentSecrets(self):
      """
      Get the current versions of all secrets inside the customer KeyVault
      """
      logger.info("getting current KeyVault secrets")
      secrets = {}
      try:
         kvSecrets = self._sendRequest("%s/secrets" % self.uri)
         logger.debug("kvSecrets=%s" % kvSecrets)
         for k in kvSecrets:
            id = k["id"].split("/")[-1]
            secrets[id] = self.getSecret(k["id"])
      except Exception as e:
         logger.error("could not get current KeyVault secrets (%s)" % e)
      return secrets

   @staticmethod
   def exists(kvName):
      """
      Check if a KeyVault with a specified name exists
      """
      logger.info("checking if KeyVault %s exists" % kvName)
      kv = AzureKeyVault(kvName)
      logger.debug("probing secrets of %s" % kv.uri)
      return (kv._sendRequest("%s/secrets" % kv.uri)) is not None

###############################################################################

class AzureLogAnalytics:
   """
   Provide access to an Azure Log Analytics WOrkspace
   """
   def __init__(self, workspaceId, sharedKey):
      logger.info("initializing Log Analytics instance")
      self.workspaceId = workspaceId
      self.sharedKey   = sharedKey
      self.uri         = "https://%s.ods.opinsights.azure.com/api/logs?api-version=2016-04-01" % workspaceId
      return

   def ingest(self, logType, jsonData):
      """
      Ingest JSON payload as custom log to Log Analytics
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
         stringHash = encodedHash.decode("utf-8")
         return "SharedKey %s:%s" % (self.workspaceId, stringHash)

      logger.info("ingesting telemetry into Log Analytics")
      timestamp = datetime.utcnow().strftime(TIME_FORMAT_LOG_ANALYTICS)
      logger.debug("timestamp=%s" % timestamp)
      headers = {
         "content-type":  "application/json",
         "Authorization": buildSig(jsonData, timestamp),
         "Log-Type":      logType,
         "x-ms-date":     timestamp,
      }
      logger.debug("headers=%s" % headers)
      logger.debug("data=%s" % jsonData)
      response = None
      try:
         response = REST.sendRequest(
            self.uri,
            method  = requests.post,
            headers = headers,
            data    = jsonData,
            )
      except Exception as e:
         logger.error("could not ingest telemetry into Log Analytics (%s)" % e)
      return response

###############################################################################

class _Context(object):
   """
   Internal context handler
   """
   hanaInstances = []

   def __init__(self, operation):
      logger.info("initializing context")
      self.vmInstance = AzureInstanceMetadataService.getComputeInstance(operation)
      vmTags = dict(map(lambda s : s.split(':'), self.vmInstance["tags"].split(";")))
      logger.debug("vmTags=%s" % vmTags)
      self.sapmonId = vmTags["SapMonId"]
      logger.debug("sapmonId=%s " % self.sapmonId)
      self.azKv = self.identifyKeyVault(vmTags.get("SapMonMsiClientId", None))
      self.lastPull = None
      self.lastResultHashes = {}
      self.readStateFile()
      return

   def identifyKeyVault(self, msiClientId):
      """
      Identify the correct KeyVault name to use
      """
      logger.info("identifying KeyVault name")
      azKv = None
      kvNames = [ k % self.sapmonId for k in KEYVAULT_NAMING_CONVENTIONS ]
      for k in kvNames:
         if AzureKeyVault.exists(k):
            logger.debug("KeyVault %s exists" % k)
            azKv = AzureKeyVault(k, msiClientId)
            break
         logger.debug("KeyVault %s does not exist" % k)
      if not azKv:
         logger.critical("could not find any KeyVault named %s" % kvNames)
         sys.exit(ERROR_KEYVAULT_NOT_FOUND)
      return azKv

   def readStateFile(self):
      """
      Get most recent state (with hashes from point-in-time queries and last pull timestamp) from a local file
      """
      logger.info("reading state file")
      success = True
      try:
         with open(STATE_FILE, "r") as f:
            data = json.load(f)
         self.lastPull = datetime.strptime(data["lastPullUTC"], TIME_FORMAT_HANA)
         logger.debug("lastPull=%s" % self.lastPull)
         self.lastResultHashes = data["lastResultHashes"]
         logger.debug("lastResultHashes=%s" % self.lastResultHashes)
      except FileNotFoundError as e:
         logger.warning("state file %s does not exist" % STATE_FILE)
      except Exception as e:
         success = False
         logger.error("could not read state file %s (%s)" % (STATE_FILE, e))
      return success

   def writeStateFile(self):
      """
      Persist current state (with hashes from point-in-time queries and last pull timestamp) into a local file
      """
      logger.info("writing state file")
      success = False
      try:
         data = {
            "lastResultHashes": self.lastResultHashes,
         }
         if self.lastPull:
            data["lastPullUTC"] = self.lastPull.strftime(TIME_FORMAT_HANA)
         with open(STATE_FILE, "w") as f:
            json.dump(data, f)
         success = True
      except Exception as e:
         logger.error("could not write state file %s (%s)" % (STATE_FILE, e))
      return success

   def setLastPullTimestamp(self, timestamp):
      """
      Set the timestamp (UTC) of the last successful pull and persist to state file
      """
      logger.info("setting last pull timestamp (timestamp=%s)" % timestamp)
      self.lastPull = timestamp
      success = self.writeStateFile()
      logger.debug("lastPullTimestamp %ssuccessfully updated" % ("not " if not success else ""))
      return success

   def setResultHash(self, query, resultHash):
      """
      Set the hash of a specific (point-in-time) query and persist to state file
      """
      logger.info("setting result hash (query=%s, resultHash=%s)" % (query, resultHash))
      self.lastResultHashes[query] = resultHash
      success = self.writeStateFile()
      return success

   def fetchHanaPasswordFromKeyVault(self, passwordKeyVault, passwordKeyVaultMsiClientId):
      """
      Fetch HANA password from a separate KeyVault.
      """
      vaultNameSearch = re.search("https://(.*).vault.azure.net", passwordKeyVault)
      logger.debug("vaultNameSearch=%s" % vaultNameSearch)
      kv = AzureKeyVault(vaultNameSearch.group(1), passwordKeyVaultMsiClientId)
      logger.debug("kv=%s" % kv)
      return kv.getSecret(passwordKeyVault)

   def parseSecrets(self):
      """
      Read secrets from customer KeyVault and store credentials in context.
      """
      def sliceDict(d, s):
         return {k: v for k, v in iter(d.items()) if k.startswith(s)}

      def fetchHanaPasswordFromKeyVault(self, passwordKeyVault, passwordKeyVaultMsiClientId):
         vaultNameSearch = re.search('https://(.*).vault.azure.net', passwordKeyVault)
         logger.debug("vaultNameSearch=%s" % vaultNameSearch)
         kv = AzureKeyVault(vaultNameSearch.group(1), passwordKeyVaultMsiClientId)
         logger.debug("kv=%s" % kv)
         return kv.getSecret(passwordKeyVault)

      logger.info("parsing secrets")
      secrets = self.azKv.getCurrentSecrets()

      # extract HANA instance(s) from secrets
      hanaSecrets = sliceDict(secrets, "SapHana-")
      for h in hanaSecrets.keys():
         hanaDetails  = json.loads(hanaSecrets[h])
         logger.debug("hanaDetails[%s]=%s" % (h, hanaDetails))
         if not hanaDetails["HanaDbPassword"]:
            logger.info("no HANA password provided; need to fetch password from separate KeyVault")
            try:
               password = self.fetchHanaPasswordFromKeyVault(
                  hanaDetails["HanaDbPasswordKeyVaultUrl"],
                  hanaDetails["PasswordKeyVaultMsiClientId"])
               hanaDetails["HanaDbPassword"] = password
               logger.debug("retrieved HANA password successfully from KeyVault; password=%s" % password)
            except Exception as e:
               logger.error("could not fetch HANA password (instance=%s) from separate KeyVault (%s)" % (h, e))
               continue
         try:
            hanaInstance = SapHana(hanaDetails = hanaDetails)
         except Exception as e:
            logger.error("could not create HANA instance (hanaDetails=%s) (%s)" % (hanaDetails, e))
            continue
         self.hanaInstances.append(hanaInstance)

      # extract Log Analytics credentials from secrets
      try:
         laSecret = json.loads(secrets["AzureLogAnalytics"])
      except Exception as e:
         logger.error("could not parse Log Analytics credentials (%s)" % e)
      self.azLa = AzureLogAnalytics(
         laSecret["LogAnalyticsWorkspaceId"],
         laSecret["LogAnalyticsSharedKey"]
         )
      return

###############################################################################

class _JsonEncoder(json.JSONEncoder):
   """
   Helper class to serialize datetime and Decimal objects into JSON
   """
   def default(self, o):
      if isinstance(o, decimal.Decimal):
         return float(o)
      elif isinstance(o, (datetime, date)):
         return o.isoformat()
      return super(_JsonEncoder, self).default(o)

###############################################################################

def getPayloadDir():
   return os.path.dirname(os.path.realpath(__file__))

def onboard(args):
   """
   Store credentials in the customer KeyVault
   (To be executed as custom script upon initial deployment of collector VM)
   """
   logger.info("starting onboarding payload")

   # Credentials (provided by user) to the existing HANA instance
   hanaSecretName = "SapHana-%s" % args.HanaDbName
   logger.debug("hanaSecretName=%s" % hanaSecretName)
   hanaSecretValue = json.dumps({
      "HanaHostname":                args.HanaHostname,
      "HanaDbName":                  args.HanaDbName,
      "HanaDbUsername":              args.HanaDbUsername,
      "HanaDbPassword":              args.HanaDbPassword,
      "HanaDbPasswordKeyVaultUrl":   args.HanaDbPasswordKeyVaultUrl,
      "HanaDbSqlPort":               args.HanaDbSqlPort,
      "PasswordKeyVaultMsiClientId": args.PasswordKeyVaultMsiClientId,
      })
   logger.debug("hanaSecretValue=%s" % hanaSecretValue)
   logger.info("storing HANA credentials as KeyVault secret")
   try:
      ctx.azKv.setSecret(hanaSecretName, hanaSecretValue)
   except Exception as e:
      logger.critical("could not store HANA credentials in KeyVault secret (%s)" % e)
      sys.exit(ERROR_SETTING_KEYVAULT_SECRET)

   # Credentials (created by HanaRP) to the newly created Log Analytics Workspace
   laSecretName = "AzureLogAnalytics"
   logger.debug("laSecretName=%s" % laSecretName)
   laSecretValue = json.dumps({
      "LogAnalyticsWorkspaceId": args.LogAnalyticsWorkspaceId,
      "LogAnalyticsSharedKey":   args.LogAnalyticsSharedKey,
      })
   logger.debug("laSecretValue=%s" % laSecretValue)
   logger.info("storing Log Analytics credentials as KeyVault secret")
   try:
      ctx.azKv.setSecret(laSecretName, laSecretValue)
   except Exception as e:
      logger.critical("could not store Log Analytics credentials in KeyVault secret (%s)" % e)
      sys.exit(ERROR_SETTING_KEYVAULT_SECRET)

   hanaDetails = json.loads(hanaSecretValue)
   logger.debug("hanaDetails=%s" % hanaDetails)
   if not hanaDetails["HanaDbPassword"]:
      logger.info("no HANA password provided; need to fetch password from separate KeyVault")
      hanaDetails["HanaDbPassword"] = ctx.fetchHanaPasswordFromKeyVault(
         hanaDetails["HanaDbPasswordKeyVaultUrl"],
         hanaDetails["PasswordKeyVaultMsiClientId"])

   # Check connectivity to HANA instance
   logger.info("connecting to HANA instance to run test query")
   try:
      hana = SapHana(hanaDetails = hanaDetails)
      hana.connect()
      hana.runQuery("SELECT 0 FROM DUMMY")
      hana.disconnect()
   except Exception as e:
      logger.critical("could not connect to HANA instance and run test query (%s)" % e)
      sys.exit(ERROR_HANA_CONNECTION)

   logger.info("onboarding payload successfully completed")
   return

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
   logger.info("starting monitor payload")
   ctx.parseSecrets()
   for h in ctx.hanaInstances:
      try:
         h.connect()
      except Exception as e:
         logger.critical("could not connect to HANA instance (%s)" % e)
         sys.exit(ERROR_HANA_CONNECTION)

      # TODO(tniek): Implement proper query framework

      try:
         # HANA Host Configuration
         colIndex, resultRows = h.getHostConfig()
         resultHash = h.getNewResultHash("HostConfig", resultRows)
         if resultHash:
            jsonData = h.convertIntoJson(colIndex, resultRows)
            ctx.azLa.ingest("SapHana_HostConfig", jsonData)
            ctx.setResultHash("HostConfig", resultHash)
      except Exception as e:
         logger.error("could not process HANA Host Config (%s)" % e)

      try:
         # HANA Load History
         if not ctx.lastPull:
            fromTimestamp = None
         else:
            fromTimestamp = ctx.lastPull + timedelta(seconds=1)
         colIndex, resultRows = h.getLoadHistory(fromTimestamp)
         if len(resultRows) > 0:
            jsonData = h.convertIntoJson(colIndex, resultRows)
            ctx.azLa.ingest("SapHana_LoadHistory", jsonData)
            lastPull = resultRows[-1][colIndex["UTC_TIMESTAMP"]]
            ctx.setLastPullTimestamp(lastPull)
      except Exception as e:
         logger.error("could not process HANA Load History (%s)" % e)

      try:
         h.disconnect()
      except Exception as e:
         logger.error("could not disconnect from HANA instance (%s)" % e)

   logger.info("monitor payload successfully completed")
   return
      
def main():
   global ctx, logger
   parser = argparse.ArgumentParser(description="SAP Monitor Payload")
   parser.add_argument("--verbose", action="store_true", dest="verbose", help="run in verbose mode") 
   subParsers = parser.add_subparsers(title="actions", help="Select action to run")
   subParsers.required = True
   subParsers.dest = "command"
   onbParser = subParsers.add_parser("onboard", description="Onboard payload", help="Onboard payload by adding credentials into KeyVault")
   onbParser.set_defaults(func=onboard, command="onboard")
   onbParser.add_argument("--HanaHostname", required=True, type=str, help="Hostname of the HDB to be monitored")
   onbParser.add_argument("--HanaDbName", required=True, type=str, help="Name of the tenant DB (empty if not MDC)")
   onbParser.add_argument("--HanaDbUsername", required=True, type=str, help="DB username to connect to the HDB tenant")
   onbParser.add_argument("--HanaDbPassword", required=False, type=str, help="DB user password to connect to the HDB tenant")
   onbParser.add_argument("--HanaDbPasswordKeyVaultUrl", required=False, type=str, help="Link to the KeyVault secret containing DB user password to connect to the HDB tenant")
   onbParser.add_argument("--HanaDbSqlPort", required=True, type=int, help="SQL port of the tenant DB")
   onbParser.add_argument("--LogAnalyticsWorkspaceId", required=True, type=str, help="Workspace ID (customer ID) of the Log Analytics Workspace")
   onbParser.add_argument("--LogAnalyticsSharedKey", required=True, type=str, help="Shared key (primary) of the Log Analytics Workspace")
   onbParser.add_argument("--PasswordKeyVaultMsiClientId", required=False, type=str, help="MSI Client ID used to get the access token from IMDS")
   monParser  = subParsers.add_parser("monitor", description="Monitor payload", help="Execute the monitoring payload")
   monParser.set_defaults(func=monitor)
   args = parser.parse_args()
   if args.verbose:
      LOG_CONFIG["handlers"]["console"]["formatter"] = "detailed"
      LOG_CONFIG["handlers"]["console"]["level"] = logging.DEBUG
   logging.config.dictConfig(LOG_CONFIG)
   logger = logging.getLogger(__name__)
   ctx = _Context(args.command)
   args.func(args)

logger = None
ctx    = None
if __name__ == "__main__":
   main()


#!/usr/bin/env python3
# 
#       SapMonitor payload deployed on collector VM
#
#       License:        GNU General Public License (GPL)
#       (c) 2019        Microsoft Corp.
#

import context

from requests.auth import HTTPBasicAuth
from helper import *

# Configure timeout for response from SMP
resp_timeout_sec = 10

class DLM:
    url_tech  = "https://tech.support.sap.com/odata/svt/swdcuisrv/DownloadContentSet"
    url_token = "https://origin.softwaredownloads.sap.com/tokengen/"

    sess      = None

    @staticmethod
    def init():
        DLM.sess = HTTPSession(
        auth     = HTTPBasicAuth(
                Config.credentials.sap_user,
                Config.credentials.sap_password
            ),
        headers  = {
                "User-Agent": "SAP Download Manager",
            },
        )

    @staticmethod
    def refresh_basket(basket):
        payload = {
            "_MODE"        : "BASKET_CONTENT",
            "J_VERSION"    : "11.0.2",
            "J_VM_VERSION" : "11.0.2+9-LTS",
            "J_VENDOR"     : "Oracle Corporation",
            "J_VM_NAME"    : "Java HotSpot(TM) 64-Bit Server VM",
            "OS_NAME"      : "Mac OS X",
            "OS_ARCH"      : "x86_64",
            "OS_VERSION"   : "10.14.2",
            "_VERSION"     : "3.1.1.patch1",
            "$format"      : "json",
        }
        resp  = DLM.sess.get(DLM.url_tech, params=payload)

        assert(resp.status_code != 401), \
            "Invalid SAP username/password"
        assert(resp.status_code == 200), \
            "Unexpected response when refreshing basket; status = %d" % (resp.status_code)

        j = json.loads(resp.content)
        if j.get("d", None):
            results = j["d"].get("results", [])
            for r in results:
                if "Value" not in r:
                    continue
                values = r["Value"].split("|")
                if len(values) != 7:
                    continue
                dl_id   = str(values[0])
                dl_desc = str(values[2])
                dl_size = int(values[3])
                dl_time = int(values[5])
                basket.add_item(DownloadItem(
                    id         = dl_id,
                    desc       = dl_desc,
                    size       = dl_size,
                    time       = dl_time,
                    target_dir = "APP",
                ))


class DownloadItem:
    id       = ""
    desc     = ""
    size     = 0
    time     = 0
    filename = ""
    last_pos = 0

    def __init__(self, id=None, desc=None, size=None, time=None, filename=None, target_dir=None, last_pos=None):
        self.id         = id if id else ""
        self.desc       = desc if desc else ""
        self.size       = size if size else 0
        self.time       = time if time else 0
        self.filename   = filename if filename else ""
        self.target_dir = target_dir if target_dir else ""
        self.last_pos   = last_pos if last_pos else 0

    def download(self):
        payload = {
            "file":   self.id,
        }
        DLM.sess.cookies.clear()
        success = False

        # First request to get the file information
        while True:
            resp  = DLM.sess.get(DLM.url_token, params=payload, timeout=resp_timeout_sec, stream=True)
            if resp.status_code == 200:
                break
            print("Received status code %d -> retrying..." % resp.status_code)
        assert(resp.status_code == 200), \
            "Unexpected response from DLM; status = %d" % (resp.status_code)

        if not "content-disposition" in resp.headers:
            return
        disposition = resp.headers["content-disposition"]
        if disposition.find('filename="') < 0:
            return
        filename = disposition.replace('"', '')
        if self.time != 0:
            directory = os.path.join(os.getcwd(), str(self.time), self.target_dir)
        else:
            directory = os.path.join(os.getcwd(), "bits", self.target_dir)
        if not os.path.exists(directory):
            os.makedirs(directory)
        target = os.path.join(directory, filename)

        if "content-length" in resp.headers:
            expected_length = int(resp.headers["content-length"])
            if os.path.isfile(target):
                if os.path.getsize(target) == expected_length:
                    print("file exists already")
                    success = True
                    return success
                else:
                    self.last_pos = os.path.getsize(target)
                    print("current file size is %s ..." % self.last_pos)
        if context.skip_download:
            return True

        # Second request to download the file from new or resume
        while True:
            resume_header = ({'Range': 'bytes={self.last_pos}-'})
            resp  = DLM.sess.get(DLM.url_token, params=payload, timeout=resp_timeout_sec, stream=True, headers=resume_header)
            if self.last_pos > 0:
                print("Resume at last_pos %s" % self.last_pos)
            if resp.status_code == 200:
                break
            print("Received status code %d -> retrying..." % resp.status_code)
        assert(resp.status_code == 200), \
            "Unexpected response from DLM; status = %d" % (resp.status_code)

        with open(target, "wb") as f:
            try:
                for chunk in resp.iter_content(chunk_size=8192):
                    if chunk: # filter out keep-alive new chunks
                        f.write(chunk)
                        f.flush()
                success = True
            except Exception as e:
                print("Exception %s happens, retry..." % e)
        return success

class DownloadBasket:
    items   = []
    total_size  = 0
    latest    = 0

    def add_item(self, i):
        if i.time > self.latest:
            self.latest = i.time
        self.total_size += i.size
        self.items.append(i)

    def filter_latest(self):  
        cnt = 0
        while cnt < len(self.items):
            if self.items[cnt].time != self.latest:
                self.total_size -= self.items[cnt].size
                self.items.pop(cnt)
                continue
            cnt += 1

    def download_all(self):
        total_complete_size = 0
        for cnt in range(len(self.items)):
            i = self.items[cnt]
            print("%-9s %-42s %12s - %10s" % (
                "(%d/%d)" % (cnt+1, len(self.items)),
                "%s" % ((i.desc[:40] + '..') if len(i.desc) > 40 else i.desc),
                "(%d KB)" % (i.size),
                "Done: %3d%%" % (int(float(total_complete_size) / float(self.total_size)*100)),
            ))
                        
            success = False
            while not success:
                success = i.download()
                        
            total_complete_size += i.size
        print("%65s - Done: 100%%" % ("(%d KB)" % self.total_size))

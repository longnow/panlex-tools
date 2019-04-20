import string
from time import sleep
from glob import glob
import os
import requests

def postagain(url, data, timeout=60, time_between_retries=60, max_retries=5):
    if max_retries < 0:
        raise requests.Timeout
    try:
        return requests.post(url, data, timeout=timeout)
    except (requests.Timeout, requests.ConnectionError) as e:
        print("waiting...")
        sleep(time_between_retries)
        print("retrying")
        s = requests.Session()
        return postagain(url, data, timeout, time_between_retries, max_retries - 1)

def scrape(lang):
    done_pages = {os.path.splitext(os.path.split(f)[1])[0] for f in glob("pages/*.html")}    
    data = f"dict={lang}&language={lang}&orth={{}}&show=self&approximateWords=on&ignoreDiacritic=on"
    url = f"http://sealang.net/{lang}/search.pl"

    for c in string.ascii_lowercase:
        if c in done_pages: continue
        r = postagain(url, data.format(f"{c}*"))
        if len(r.text) < 1000:
            for c2 in string.ascii_lowercase:
                l = c + c2
                if l in done_pages: continue
                r = postagain(url, data.format(f"{l}*"))
                if len(r.text) < 1000:
                    for c3 in string.ascii_lowercase:
                        l = c + c2 + c3
                        if l in done_pages: continue
                        r = postagain(url, data.format(f"{l}*"))
                        if len(r.text) < 1000:
                            print("too many entries at " + l)
                            raise IndexError
                        print(l)
                        open(f"pages/{l}.html", "w").write(r.text)
                    open(f"pages/{c + c2}.html", "w").write("SPLIT")
                else:
                    print(c + c2)
                    open(f"pages/{l}.html", "w").write(r.text)
            open(f"pages/{c}.html", "w").write("SPLIT")
        else:
            print(c)
            open(f"pages/{c}.html", "w").write(r.text)

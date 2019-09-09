#!/usr/bin/env python3

import requests
import argparse
import sys
import time

p = argparse.ArgumentParser()
p.add_argument("url")
p.add_argument("tries", type=int)
p.add_argument("--http-code", type=int)

ns = p.parse_args()

tries = 0
while tries < ns.tries:
    time.sleep(1)

    print("Waiting for proxy, try %d of %d" % (tries+1, ns.tries))
    
    tries+=1
    code = None
    try:
        code = requests.get(ns.url).status_code
    except requests.exceptions.ConnectionError:
        pass
    if code is not None:
        if ns.http_code is None:
            sys.exit(0)
        else:
            if ns.http_code == code:
                sys.exit(0)

sys.exit(1)

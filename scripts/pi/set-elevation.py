#!/usr/bin/env python3
"""Set HA elevation in core.config storage file. Runs on the Pi."""
import json
import shutil
import sys

if len(sys.argv) != 2:
    sys.exit("usage: set-elevation.py <meters>")

new_elev = int(sys.argv[1])
PATH = "/home/papi/ha-config/.storage/core.config"

with open(PATH) as f:
    d = json.load(f)

old = d["data"].get("elevation")
d["data"]["elevation"] = new_elev

with open(PATH + ".tmp", "w") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
shutil.move(PATH + ".tmp", PATH)
print(f"elevation: {old} -> {new_elev}")

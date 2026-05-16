#!/usr/bin/env python3
"""Merge /tmp/dashboard.yaml into HA dashboard storage JSON. Runs on the Pi."""
import json
import shutil
import yaml

DASHYAML = "/tmp/dashboard.yaml"
STORAGE = "/home/papi/ha-config/.storage/lovelace.dashboard_skylight"

with open(DASHYAML) as f:
    new_config = yaml.safe_load(f)

with open(STORAGE) as f:
    store = json.load(f)

store["data"]["config"] = new_config

with open(STORAGE + ".tmp", "w") as f:
    json.dump(store, f, indent=2, ensure_ascii=False)
shutil.move(STORAGE + ".tmp", STORAGE)

views = store["data"]["config"].get("views", [])
sections = views[0].get("sections", []) if views else []
print(f"merged. views={len(views)} sections={len(sections)}")

#!/usr/bin/env python3
"""
Rename the NWS weather entity to weather.colorado_springs and remove the
met.no config entry plus its orphan entities. Runs on the Pi.
"""
import json
import shutil

REGISTRY = "/home/papi/ha-config/.storage/core.entity_registry"
CONFIG_ENTRIES = "/home/papi/ha-config/.storage/core.config_entries"

OLD_WEATHER = "weather.nws_38_9786874_104_7824769_kaff"
NEW_WEATHER = "weather.colorado_springs"

shutil.copy(REGISTRY, REGISTRY + ".bak.preCleanup")
shutil.copy(CONFIG_ENTRIES, CONFIG_ENTRIES + ".bak.preCleanup")

with open(CONFIG_ENTRIES) as f:
    ce = json.load(f)

met_entry_id = None
for e in ce["data"]["entries"]:
    if e.get("domain") == "met":
        met_entry_id = e.get("entry_id")
        break

new_entries = [e for e in ce["data"]["entries"] if e.get("domain") != "met"]
removed_config = len(ce["data"]["entries"]) - len(new_entries)
ce["data"]["entries"] = new_entries

with open(CONFIG_ENTRIES + ".tmp", "w") as f:
    json.dump(ce, f, indent=2, ensure_ascii=False)
shutil.move(CONFIG_ENTRIES + ".tmp", CONFIG_ENTRIES)

with open(REGISTRY) as f:
    reg = json.load(f)

renamed = 0
removed_met_entities = 0
kept = []
for ent in reg["data"]["entities"]:
    if met_entry_id and ent.get("config_entry_id") == met_entry_id:
        removed_met_entities += 1
        continue
    if ent.get("entity_id") == OLD_WEATHER:
        ent["entity_id"] = NEW_WEATHER
        renamed += 1
    kept.append(ent)

reg["data"]["entities"] = kept

with open(REGISTRY + ".tmp", "w") as f:
    json.dump(reg, f, indent=2, ensure_ascii=False)
shutil.move(REGISTRY + ".tmp", REGISTRY)

print(f"removed met config entries: {removed_config}")
print(f"removed met-owned entities: {removed_met_entities}")
print(f"renamed NWS weather entity: {renamed}")

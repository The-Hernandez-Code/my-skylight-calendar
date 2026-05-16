#!/usr/bin/env python3
"""Dump HA dashboard storage as YAML to stdout. Runs on the Pi."""
import json
import sys
import yaml

STORAGE = "/home/papi/ha-config/.storage/lovelace.dashboard_skylight"

with open(STORAGE) as f:
    data = json.load(f)

yaml.safe_dump(
    data["data"]["config"],
    sys.stdout,
    default_flow_style=False,
    sort_keys=False,
    allow_unicode=True,
    width=120,
)

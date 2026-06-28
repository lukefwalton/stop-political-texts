#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f project.local.yml ]; then
  cp project.local.yml.example project.local.yml
  echo "Created project.local.yml — set DEVELOPMENT_TEAM, then re-run this script."
  exit 1
fi

if grep -q 'YOUR_TEAM_ID_HERE' project.local.yml; then
  echo "Edit project.local.yml and replace YOUR_TEAM_ID_HERE with your Team ID." >&2
  exit 1
fi

# Merge project.yml + project.local.yml for XcodeGen (local file is gitignored).
python3 - <<'PY'
import yaml
from pathlib import Path

def deep_merge(base, override):
    for key, value in override.items():
        if key in base and isinstance(base[key], dict) and isinstance(value, dict):
            deep_merge(base[key], value)
        else:
            base[key] = value

root = Path(".")
spec = yaml.safe_load(root.joinpath("project.yml").read_text())
local = yaml.safe_load(root.joinpath("project.local.yml").read_text())
deep_merge(spec, local)
root.joinpath("project.generated.yml").write_text(yaml.dump(spec, sort_keys=False))
PY

xcodegen generate --spec project.generated.yml
rm -f project.generated.yml

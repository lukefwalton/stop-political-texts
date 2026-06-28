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

if ! command -v ruby >/dev/null 2>&1; then
  echo "ruby not found (required to merge project.yml + project.local.yml)." >&2
  exit 1
fi

# Merge project.yml + project.local.yml for XcodeGen (local file is gitignored).
ruby -ryaml -e '
require "yaml"

def deep_merge(base, override)
  override.each do |key, value|
    if base[key].is_a?(Hash) && value.is_a?(Hash)
      deep_merge(base[key], value)
    else
      base[key] = value
    end
  end
end

spec = YAML.load_file("project.yml")
local = YAML.load_file("project.local.yml")
deep_merge(spec, local)
File.write("project.generated.yml", spec.to_yaml)
'

xcodegen generate --spec project.generated.yml
rm -f project.generated.yml

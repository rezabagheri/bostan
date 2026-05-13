#!/usr/bin/env bash
# lib/config.sh - Read/write site config JSON files

_sites_dir() {
  echo "${PDEV_ROOT}/sites"
}

config_path() {
  local name="$1"
  echo "$(_sites_dir)/${name}/config.json"
}

config_get() {
  local name="$1" key="$2"
  local file; file="$(config_path "$name")"
  [[ -f "$file" ]] || return 1
  python3 - "$file" "$key" <<'PY'
import sys, json
from functools import reduce

def dig(obj, path):
    try:
        return reduce(lambda o, k: o[k], path.split('.'), obj)
    except (KeyError, TypeError):
        return ''

data = json.load(open(sys.argv[1]))
result = dig(data, sys.argv[2])
print(result if not isinstance(result, (dict, list)) else json.dumps(result))
PY
}

config_set() {
  local name="$1" key="$2" value="$3"
  local file; file="$(config_path "$name")"
  [[ -f "$file" ]] || return 1
  python3 - "$file" "$key" "$value" <<'PY'
import sys, json

def set_nested(obj, path, value):
    keys = path.split('.')
    for k in keys[:-1]:
        obj = obj.setdefault(k, {})
    if isinstance(value, str) and value.isdigit():
        value = int(value)
    elif isinstance(value, str) and value.lower() in ('true', 'false'):
        value = value.lower() == 'true'
    obj[keys[-1]] = value

file = sys.argv[1]
data = json.load(open(file))
set_nested(data, sys.argv[2], sys.argv[3])
with open(file, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
PY
}

config_create() {
  local name="$1" type="$2" port="$3"
  local dir; dir="$(_sites_dir)/${name}"
  mkdir -p "$dir"

  PDEV_ROOT="$PDEV_ROOT" python3 - "$name" "$type" "$port" <<'PY'
import sys, json, os

name, site_type, port = sys.argv[1], sys.argv[2], sys.argv[3]
sites_dir = os.environ.get('PDEV_ROOT', '.') + '/sites'

config = {
  "site_name": name,
  "type": site_type,
  "db": {
    "engine": "mysql",
    "name": f"pdev_{name}"
  },
  "port": int(port),
  "wp": {
    "title": f"{name.capitalize()} Site",
    "admin_user": "admin",
    "admin_password": "admin123",
    "admin_email": "admin@example.com",
    "locale": "en_US"
  },
  "plugins": [],
  "settings": {}
}

out = f"{sites_dir}/{name}/config.json"
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
PY
}

config_list_sites() {
  local sites_dir; sites_dir="$(_sites_dir)"
  [[ -d "$sites_dir" ]] || return 0
  local found=false
  for dir in "$sites_dir"/*/; do
    local f="${dir}config.json"
    if [[ -f "$f" ]]; then
      basename "$dir"
      found=true
    fi
  done
  # Return 0 even if no sites found (avoid set -e exit)
  return 0
}

site_exists() {
  local name="$1"
  [[ -f "$(config_path "$name")" ]]
}

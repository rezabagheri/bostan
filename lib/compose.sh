#!/usr/bin/env bash
# lib/compose.sh - docker-compose service injection and removal

_compose_file() {
  echo "${PDEV_ROOT}/docker-compose.yml"
}

compose_add_service() {
  local service_name="$1"
  local service_yaml="$2"
  local volume_name="$3"
  local compose_file; compose_file="$(_compose_file)"

  python3 - "$compose_file" "$service_name" "$volume_name" "$service_yaml" <<'PY'
import sys

compose_file  = sys.argv[1]
service_name  = sys.argv[2]
volume_name   = sys.argv[3]
service_block = sys.argv[4]

text = open(compose_file).read()

if f"\n  {service_name}:" in text:
    print(f"ERROR: Service '{service_name}' already exists", file=sys.stderr)
    sys.exit(1)

# Find the "# Sites" comment or the volumes section
sites_marker = "\n  # Sites are added by `pdev site add`\n"
volumes_marker = "\nvolumes:\n"

if sites_marker in text:
    text = text.replace(sites_marker, sites_marker + service_block + "\n")
elif volumes_marker in text:
    text = text.replace(volumes_marker, service_block + "\n" + volumes_marker)
else:
    print("ERROR: Could not find insertion point in docker-compose.yml", file=sys.stderr)
    sys.exit(2)

# Add volume entry under volumes:
idx = text.index(volumes_marker) + len(volumes_marker)
text = text[:idx] + f"  {volume_name}:\n" + text[idx:]

with open(compose_file, "w") as f:
    f.write(text)

print(f"Service '{service_name}' added to docker-compose.yml")
PY
}

compose_remove_service() {
  local service_name="$1"
  local volume_name="$2"
  local compose_file; compose_file="$(_compose_file)"

  python3 - "$compose_file" "$service_name" "$volume_name" <<'PY'
import sys, re

compose_file = sys.argv[1]
service_name = sys.argv[2]
volume_name  = sys.argv[3]

text = open(compose_file).read()

# Remove service block
pattern = rf"\n  {re.escape(service_name)}:.*?(?=\n  [a-zA-Z#]|\nvolumes:|\Z)"
text = re.sub(pattern, "", text, flags=re.DOTALL)

# Remove volume entry
text = re.sub(rf"\n  {re.escape(volume_name)}:\s*\n?", "\n", text)

with open(compose_file, "w") as f:
    f.write(text)

print(f"Service '{service_name}' removed from docker-compose.yml")
PY
}

compose_status() {
  local service_name="$1"
  local compose_file; compose_file="$(_compose_file)"
  local status
  status=$(docker compose -f "$compose_file" ps --format json 2>/dev/null \
    | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        if d.get('Service') == sys.argv[1]:
            print(d.get('State','unknown'))
            sys.exit(0)
    except Exception:
        pass
print('stopped')
" "$service_name" 2>/dev/null || echo "stopped")
  echo "$status"
}

compose_up() {
  local service_name="$1"
  local compose_file; compose_file="$(_compose_file)"
  docker compose -f "$compose_file" up -d "$service_name"
}

compose_down() {
  local service_name="$1"
  local compose_file; compose_file="$(_compose_file)"
  docker compose -f "$compose_file" stop "$service_name"
}

compose_rm() {
  local service_name="$1"
  local compose_file; compose_file="$(_compose_file)"
  docker compose -f "$compose_file" stop "$service_name" 2>/dev/null || true
  docker compose -f "$compose_file" rm -f "$service_name" 2>/dev/null || true
}
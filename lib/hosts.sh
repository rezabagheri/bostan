#!/usr/bin/env bash
# lib/hosts.sh — /etc/hosts management

HOSTS_FILE="/etc/hosts"
PDEV_MARKER="# pdev-managed"

# Add one or more hosts
hosts_add() {
  local ip="${1:-127.0.0.1}"
  shift
  local hosts=("$@")

  for host in "${hosts[@]}"; do
    if grep -qE "^\s*${ip}\s+${host}(\s|$)" "$HOSTS_FILE" 2>/dev/null; then
      dim "  Already in hosts: ${host}"
      continue
    fi
    echo "${ip}    ${host}    ${PDEV_MARKER}" | sudo tee -a "$HOSTS_FILE" > /dev/null
    success "Added to hosts: ${host}"
  done
}

# Remove a host added by pdev
hosts_remove() {
  local host="$1"
  if grep -q "${host}.*${PDEV_MARKER}" "$HOSTS_FILE" 2>/dev/null; then
    sudo sed -i.bak "/${host}.*${PDEV_MARKER}/d" "$HOSTS_FILE"
    success "Removed from hosts: ${host}"
  else
    dim "  Not in hosts (or not managed by pdev): ${host}"
  fi
}

# List all hosts managed by pdev
hosts_list() {
  grep "${PDEV_MARKER}" "$HOSTS_FILE" 2>/dev/null | awk '{print $2}' || true
}
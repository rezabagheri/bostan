#!/usr/bin/env bash
# lib/port.sh — Automatically find an available port

PORT_START=8090

# Get all ports currently used by existing sites
used_ports() {
  config_list_sites | while read -r name; do
    config_get "$name" "port" 2>/dev/null
  done
}

# Find the first available port
find_free_port() {
  local port=$PORT_START
  local used
  used="$(used_ports | sort -n)"

  while true; do
    # Check that the port is not used by any site and not open on the system
    if ! echo "$used" | grep -q "^${port}$" && \
       ! (ss -tlnH 2>/dev/null || netstat -tlnH 2>/dev/null) | grep -q ":${port} "; then
      echo "$port"
      return 0
    fi
    (( port++ ))
  done
}
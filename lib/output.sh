#!/usr/bin/env bash
# lib/output.sh - Colors, messages, and table output

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()    { echo -e "${BLUE}i${RESET}  $*"; }
success() { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}!${RESET}  $*"; }
error()   { echo -e "${RED}✖${RESET}  $*" >&2; }
fatal()   { error "$*"; exit 1; }
step()    { echo -e "${CYAN}→${RESET}  ${BOLD}$*${RESET}"; }
dim()     { echo -e "${DIM}   $*${RESET}"; }

confirm() {
  local msg="${1:-Are you sure?}"
  echo -en "${YELLOW}?${RESET}  ${msg} [y/N] "
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

print_table_header() {
  printf "${BOLD}%-20s %-12s %-28s %-10s %-6s${RESET}\n" \
    "NAME" "TYPE" "URL" "STATUS" "PORT"
  printf '%0.s─' {1..78}
  echo ""
}

print_table_row() {
  local name="$1" type="$2" url="$3" status="$4" port="$5"
  local color="$RESET"
  [[ "$status" == "running" ]] && color="$GREEN"
  [[ "$status" == "exited"  ]] && color="$RED"
  [[ "$status" == "stopped" ]] && color="$RED"
  printf "%-20s %-12s %-28s ${color}%-10s${RESET} %-6s\n" \
    "$name" "$type" "$url" "$status" "$port"
}

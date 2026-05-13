#!/usr/bin/env bash
# lib/db.sh - Database operations: create / drop / export / import / clone

DB_CONTAINER="pdev-db"
DB_ROOT_PASS="rootpass"

_mysql() {
  docker exec "$DB_CONTAINER" \
    mysql -uroot -p"${DB_ROOT_PASS}" -e "$1" 2>/dev/null
}

db_create() {
  local db_name="$1"
  step "Creating database: ${db_name}"
  _mysql "CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  _mysql "GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO 'wordpress'@'%';"
  _mysql "FLUSH PRIVILEGES;"
  success "Database '${db_name}' created"
}

db_drop() {
  local db_name="$1"
  step "Dropping database: ${db_name}"
  _mysql "DROP DATABASE IF EXISTS \`${db_name}\`;"
  success "Database '${db_name}' dropped"
}

db_export() {
  local site_name="$1"
  local db_name; db_name="$(config_get "$site_name" "db.name")"
  local output="${2:-${PDEV_ROOT}/sites/${site_name}/backup_$(date +%Y%m%d_%H%M%S).sql}"

  step "Exporting '${db_name}' -> ${output}"
  docker exec "$DB_CONTAINER" \
    mysqldump -uroot -p"${DB_ROOT_PASS}" \
    --single-transaction --routines --triggers \
    "$db_name" > "$output"
  success "Exported to: ${output}"
  echo "$output"
}

db_import() {
  local site_name="$1"
  local file="$2"
  local db_name; db_name="$(config_get "$site_name" "db.name")"

  [[ -f "$file" ]] || fatal "File not found: $file"
  step "Importing ${file} -> '${db_name}'"
  docker exec -i "$DB_CONTAINER" \
    mysql -uroot -p"${DB_ROOT_PASS}" "$db_name" < "$file"
  success "Import complete"
}

db_clone() {
  local src_site="$1"
  local dst_site="$2"
  local src_db; src_db="$(config_get "$src_site" "db.name")"
  local dst_db; dst_db="$(config_get "$dst_site" "db.name")"

  step "Cloning database '${src_db}' -> '${dst_db}'"
  docker exec "$DB_CONTAINER" \
    mysqldump -uroot -p"${DB_ROOT_PASS}" --single-transaction "$src_db" \
  | docker exec -i "$DB_CONTAINER" \
    mysql -uroot -p"${DB_ROOT_PASS}" "$dst_db"
  success "Database cloned"
}

db_check_running() {
  docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${DB_CONTAINER}$" \
    || fatal "Database container '${DB_CONTAINER}' is not running. Run: pdev setup"
}

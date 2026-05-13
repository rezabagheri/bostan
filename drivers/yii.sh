#!/usr/bin/env bash
# drivers/yii.sh — Yii driver (stub — under development)

driver_yii_required_args() {
  echo ""
}

driver_yii_compose_service() {
  local name="$1" port="$2" db_name="$3"
  local hostname="${name}.test"

  cat <<YAML

  ${name}:
    image: php:8.1-fpm
    restart: unless-stopped
    depends_on:
      - db
    environment:
      DB_HOST: db
      DB_DATABASE: ${db_name}
      DB_USERNAME: wordpress
      DB_PASSWORD: wordpress
      VIRTUAL_HOST: ${hostname}
    volumes:
      - ${name}_data:/var/www/html
    networks:
      - pdev
    labels:
      pdev.site: "${name}"
      pdev.type: "yii"
      pdev.port: "${port}"

YAML
}

driver_yii_post_install() {
  local name="$1"
  warn "Yii driver is a stub — post-install automation not yet implemented"
  info "Site '${name}' container is running. Deploy your Yii app manually."
}

driver_yii_info() {
  local name="$1"
  echo "http://${name}.test"
}
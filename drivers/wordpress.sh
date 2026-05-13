#!/usr/bin/env bash
# drivers/wordpress.sh - WordPress site driver

driver_wordpress_compose_service() {
  local name="$1" port="$2" db_name="$3" locale="$4"
  local hostname="${name}.test"

  cat <<YAML

  ${name}:
    image: wordpress:latest
    restart: unless-stopped
    depends_on:
      - db
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: ${db_name}
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      VIRTUAL_HOST: ${hostname}
      VIRTUAL_PORT: 80
    volumes:
      - ${name}_data:/var/www/html
      - ./config/php.ini:/usr/local/etc/php/conf.d/custom.ini:ro
    networks:
      - pdev
    labels:
      pdev.site: "${name}"
      pdev.type: "wordpress"
      pdev.port: "${port}"

YAML
}

driver_wordpress_post_install() {
  local name="$1"
  local port;    port="$(config_get "$name" "port")"
  local title;   title="$(config_get "$name" "wp.title")"
  local user;    user="$(config_get "$name" "wp.admin_user")"
  local pass;    pass="$(config_get "$name" "wp.admin_password")"
  local email;   email="$(config_get "$name" "wp.admin_email")"
  local locale;  locale="$(config_get "$name" "wp.locale")"
  local hostname="${name}.test"
  local compose_file="${PDEV_ROOT}/docker-compose.yml"

  step "Waiting for WordPress container to be ready..."
  local waited=0
  until docker compose -f "$compose_file" exec -T "$name" \
      curl -sf http://localhost/ &>/dev/null; do
    sleep 3
    (( waited += 3 )) || true
    if (( waited >= 90 )); then
      fatal "WordPress container did not become ready in 90s"
    fi
    printf "."
  done
  echo ""

  step "Installing WordPress via WP-CLI..."
  docker compose -f "$compose_file" exec -T "$name" bash -c "
    # Install WP-CLI if not present
    if ! command -v wp &>/dev/null; then
      curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
      chmod +x wp-cli.phar
      mv wp-cli.phar /usr/local/bin/wp
    fi

    wp core install \
      --url='http://${hostname}' \
      --title='${title}' \
      --admin_user='${user}' \
      --admin_password='${pass}' \
      --admin_email='${email}' \
      --locale='${locale}' \
      --skip-email \
      --allow-root

    wp option update blogdescription '' --allow-root
    wp rewrite structure '/%postname%/' --allow-root
    wp rewrite flush --allow-root
    echo 'WordPress installed'
  "

  # Install plugins from config
  local plugins_json; plugins_json="$(config_get "$name" "plugins")"
  if [[ "$plugins_json" != "[]" && -n "$plugins_json" ]]; then
    step "Installing plugins..."
    while IFS= read -r plugin_url; do
      docker compose -f "$compose_file" exec -T "$name" bash -c \
        "wp plugin install '${plugin_url}' --activate --allow-root" \
        && success "Plugin installed: ${plugin_url}" \
        || warn "Failed to install: ${plugin_url}"
    done < <(echo "$plugins_json" | python3 -c "import sys,json; [print(p) for p in json.load(sys.stdin)]")
  fi

  echo ""
  success "WordPress ready: http://${hostname}"
  info "Admin : http://${hostname}/wp-admin"
  info "User  : ${user}"
  info "Pass  : ${pass}"
}

driver_wordpress_info() {
  local name="$1"
  echo "http://${name}.test"
}

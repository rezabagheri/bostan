#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import time
import textwrap
import argparse
import shutil
import re
from pathlib import Path

class Output:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

    @staticmethod
    def success(msg): print(f"{Output.GREEN}✔ {msg}{Output.RESET}")
    @staticmethod
    def info(msg): print(f"{Output.BLUE}ℹ {msg}{Output.RESET}")
    @staticmethod
    def error(msg): 
        print(f"{Output.RED}✖ {msg}{Output.RESET}")
        sys.exit(1)
    @staticmethod
    def step(msg): print(f"{Output.BOLD}→ {msg}{Output.RESET}")

class PDev:
    def __init__(self):
        self.root = Path(__file__).parent.absolute()
        self.sites_dir = self.root / "sites"
        self.compose_file = self.root / "docker-compose.yml"
        self.sites_dir.mkdir(exist_ok=True)

    def is_infra_running(self):
        """Check if the core database container is running."""
        res = subprocess.run("docker ps -q -f name=pdev-db", shell=True, capture_output=True, text=True)
        return bool(res.stdout.strip())

    def run_shell(self, cmd, check=True, capture=False):
        is_shell = isinstance(cmd, str)
        try:
            if capture:
                return subprocess.run(cmd, shell=is_shell, check=check, capture_output=True, text=True, encoding='utf-8')
            return subprocess.run(cmd, shell=is_shell, check=check)
        except subprocess.CalledProcessError as e:
            stderr = e.stderr if e.stderr else "Check docker logs"
            Output.error(f"Command failed: {stderr}")

    def setup(self):
        Output.step("Checking dependencies...")
        
        # Pre-flight port check for infrastructure
        required_ports = {8888: "Proxy", 8081: "Adminer", 8027: "Mailpit UI", 1026: "Mailpit SMTP"}
        for port, service in required_ports.items():
            port_check = subprocess.run(f"lsof -nP -iTCP:{port} -sTCP:LISTEN", shell=True, capture_output=True, text=True)
            if port_check.returncode == 0:
                process_info = port_check.stdout.split('\n')[1] if port_check.stdout else "Unknown process"
                Output.error(f"Port {port} ({service}) is already in use by:\n  {process_info.strip()}\nTry to stop this process or change the port in docker-compose.yml.")

        if not subprocess.run("docker info", shell=True, capture_output=True).returncode == 0:
            Output.error("Docker is not running.")
        
        Output.step("Starting base services...")
        self.run_shell(f"docker compose -f {self.compose_file} up -d --remove-orphans db proxy mailpit adminer")
        
        Output.info("Waiting for database...")
        # Polling loop to wait for MySQL to be ready
        for _ in range(30):
            # We check exit code manually to avoid run_shell's automatic exit
            res = subprocess.run(
                f"docker exec pdev-db mysqladmin ping -h localhost -prootpass --silent 2>/dev/null",
                shell=True
            )
            if res.returncode == 0:
                print("")  # New line after the progress dots
                Output.success("Infrastructure is ready!")
                return
            print(".", end="", flush=True)
            time.sleep(2)
            
        print("")
        Output.error("Database failed to start within 60 seconds. Check 'docker logs pdev-db'.")

    def down(self):
        Output.step("Stopping all services and removing containers...")
        self.run_shell(f"docker compose -f {self.compose_file} down")
        Output.success("Cleanup complete.")

    def get_free_port(self):
        # Simple logic to find free port starting from 8090
        used_ports = []
        for site_config in self.sites_dir.glob("*/config.json"):
            with open(site_config) as f:
                used_ports.append(json.load(f).get("port"))
        
        port = 8090
        while port in used_ports:
            port += 1
        return port

    def add_site(self, name, site_type="wordpress", **kwargs):
        if (self.sites_dir / name).exists():
            Output.error(f"Site '{name}' already exists.")

        if not self.is_infra_running():
            Output.error("Infrastructure is not running. Please run: ./pdev setup")

        port = self.get_free_port()
        Output.step(f"Creating site '{name}' on port {port}...")

        # 1. Create directory and config
        site_path = self.sites_dir / name
        site_path.mkdir()
        config = {
            "name": name,
            "type": site_type,
            "port": port,
            "db_name": f"pdev_{name}"
        }
        with open(site_path / "config.json", "w") as f:
            json.dump(config, f, indent=4)

        # 2. Update docker-compose.yml (Simplified for now)
        self.inject_compose_service(name, port, config["db_name"])

        # 3. Create Database
        Output.step("Creating database...")
        # Added 2>/dev/null to hide the MySQL password warning
        self.run_shell(f"docker exec pdev-db mysql -uroot -prootpass -e 'CREATE DATABASE IF NOT EXISTS {config['db_name']}' 2>/dev/null")

        # 4. Start Container
        self.run_shell(f"docker compose -f {self.compose_file} up -d {name}")

        # 5. Post-installation logic
        if site_type == "wordpress":
            self.post_install_wordpress(name, **kwargs)

        Output.success(f"Site {name} is live at http://{name}.test:8888")

    def post_install_wordpress(self, name, **kwargs):
        url = f"http://{name}.test:8888"
        title = kwargs.get('title') or name.capitalize()
        user = kwargs.get('admin_user') or "admin"
        password = kwargs.get('admin_pass') or "admin123"
        email = kwargs.get('admin_email') or "admin@example.com"
        ready = False

        Output.step("Waiting for WordPress container to be ready...")
        for _ in range(30):
            # The official WordPress image does not have curl installed.
            # We check for index.php to ensure the entrypoint has finished extracting WP files.
            res = subprocess.run(f"docker exec {name} ls index.php", shell=True, capture_output=True)
            if res.returncode == 0:
                ready = True
                break
            print(".", end="", flush=True)
            time.sleep(3)
        print("")
        if not ready:
            Output.error(f"WordPress container '{name}' is not responding. Check 'docker logs {name}'")

        Output.step("Installing WP-CLI and setting up WordPress...")
        
        # 1. Install WP-CLI
        self.run_shell(["docker", "exec", name, "bash", "-c", "curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp"], capture=True)
        
        # 2. WP Core Install
        self.run_shell(["docker", "exec", name, "wp", "core", "install", f"--url={url}", f"--title={title}", f"--admin_user={user}", f"--admin_password={password}", f"--admin_email={email}", "--skip-email", "--allow-root"], capture=True)

        # 3. Configure WP_HOME and WP_SITEURL
        self.run_shell(["docker", "exec", name, "wp", "config", "set", "WP_HOME", url, "--type=constant", "--allow-root"], capture=True)
        self.run_shell(["docker", "exec", name, "wp", "config", "set", "WP_SITEURL", url, "--type=constant", "--allow-root"], capture=True)

        # 4. Inject Proxy Fix (Safe One-Liner)
        proxy_fix = "if(isset($_SERVER['HTTP_X_FORWARDED_HOST'])){$_SERVER['HTTP_HOST']=$_SERVER['HTTP_X_FORWARDED_HOST'];$_SERVER['SERVER_PORT']=8888;}"
        self.run_shell(["docker", "exec", name, "wp", "config", "set", "PDEV_PROXY_FIX", proxy_fix, "--raw", "--anchor=<?php", "--placement=after", "--allow-root"], capture=True)

        # 5. Permalinks
        self.run_shell(["docker", "exec", name, "wp", "rewrite", "structure", "/%postname%/", "--allow-root"], capture=True)
        
        Output.success("WordPress installation completed via WP-CLI.")
        Output.info(f"Admin URL: {url}/wp-admin")
        Output.info(f"Credentials: {user} / {password}")

    def delete_site(self, name):
        if not (self.sites_dir / name).exists():
            Output.error(f"Site '{name}' does not exist.")
        
        Output.step(f"Deleting site '{name}'...")
        # 1. Stop and remove container
        self.run_shell(f"docker compose -f {self.compose_file} stop {name}", check=False)
        self.run_shell(f"docker compose -f {self.compose_file} rm -f {name}", check=False)
        
        # 2. Drop Database
        if self.is_infra_running():
            self.run_shell(f"docker exec pdev-db mysql -uroot -prootpass -e 'DROP DATABASE IF EXISTS pdev_{name}' 2>/dev/null", check=False)
        
        # 3. Remove from docker-compose.yml
        content = self.compose_file.read_text()
        content = re.sub(rf"\n  {name}:.*?(?=\n\S|\n# \[|\Z)", "", content, flags=re.DOTALL)
        content = re.sub(rf"\n  {name}_data:.*?(?=\n\S|\n# \[|\Z)", "", content, flags=re.DOTALL)
        self.compose_file.write_text(content)
        
        # 4. Remove directory
        shutil.rmtree(self.sites_dir / name)
        Output.success(f"Site '{name}' deleted and cleaned up.")

    def inject_compose_service(self, name, port, db_name):
        service_block = f"""
  {name}:
    image: wordpress:latest
    container_name: {name}
    restart: unless-stopped
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: {db_name}
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      VIRTUAL_HOST: {name}.test
      VIRTUAL_PORT: 80
    volumes:
      - {name}_data:/var/www/html
    networks:
      - pdev
    labels:
      pdev.port: "{port}"
"""
        content = self.compose_file.read_text()

        if f"\n  {name}:" in content:
            Output.error(f"Service '{name}' is already defined in docker-compose.yml. Manual cleanup may be required.")

        # Inject service at marker
        if "# [SITES_MARKER]" in content:
            content = content.replace("# [SITES_MARKER]", service_block.strip("\n") + "\n# [SITES_MARKER]")

        # Inject volume at marker
        if "# [VOLUMES_MARKER]" in content:
            content = content.replace("# [VOLUMES_MARKER]", f"  {name}_data:\n# [VOLUMES_MARKER]")

        self.compose_file.write_text(content)

    def list_sites(self):
        Output.step("Managed Sites:")
        for site_config in self.sites_dir.glob("*/config.json"):
            with open(site_config) as f:
                data = json.load(f)
                print(f"- {data['name']} ({data['type']}): http://{data['name']}.test:8888 (Port: {data['port']})")

def main():
    parser = argparse.ArgumentParser(description="pdev — Paradise Dev CLI (Python Edition)")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("setup")
    subparsers.add_parser("down")
    
    site_parser = subparsers.add_parser("site")
    site_sub = site_parser.add_subparsers(dest="subcommand")
    
    delete_parser = site_sub.add_parser("delete")
    delete_parser.add_argument("name")

    add_parser = site_sub.add_parser("add")
    add_parser.add_argument("--name", required=True)
    add_parser.add_argument("--type", default="wordpress")
    add_parser.add_argument("--title")
    add_parser.add_argument("--admin-user")
    add_parser.add_argument("--admin-pass")
    add_parser.add_argument("--admin-email")

    site_sub.add_parser("list")

    args = parser.parse_args()
    pdev = PDev()

    if args.command == "setup":
        pdev.setup()
    elif args.command == "down":
        pdev.down()
    elif args.command == "site":
        if args.subcommand == "add":
            site_args = vars(args)
            name = site_args.pop('name')
            site_type = site_args.pop('type')
            pdev.add_site(name, site_type, **site_args)
        elif args.subcommand == "delete":
            pdev.delete_site(args.name)
        elif args.subcommand == "list":
            pdev.list_sites()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
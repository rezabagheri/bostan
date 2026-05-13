# pdev — Paradise Dev CLI

Manage local development environments with Docker.

## Requirements

- Docker + Docker Compose v2
- bash
- python3

## Installation

```
git clone https://github.com/ParadiseCyber/pdev.git
cd pdev
chmod +x pdev lib/*.sh drivers/*.sh

# Initial setup
./pdev setup
```

## Usage

### Adding a Site

```
# WordPress (default)
./pdev site add --name myblog --type wordpress

# With full configuration
./pdev site add \
  --name shop \
  --type wordpress \
  --title "My Shop" \
  --locale en_US \
  --admin-user admin \
  --admin-pass secret123 \
  --admin-email me@example.com

# Dry run (preview without execution)
./pdev site add --name test --dry-run
```

### Site Management

```
./pdev site list           # List all sites
./pdev site status         # Status of all sites
./pdev site up myblog      # Start
./pdev site down myblog    # Stop
./pdev site delete myblog  # Full removal
./pdev site clone myblog --as myblog-staging  # Full clone
```

### Database

```
./pdev db export myblog                        # Backup
./pdev db export myblog --output backup.sql    # Backup with custom name
./pdev db import myblog --file backup.sql      # Restore
./pdev db drop myblog                          # Drop database
```

### Plugins (WordPress)

```
./pdev plugins sync myblog    # Install plugins from config.json
./pdev plugins update myblog  # Update all plugins
```

## Project Structure

```
pdev/
├── pdev                  ← Main command
├── docker-compose.yml    ← Base services
├── lib/
│   ├── output.sh         ← Messages and color formatting
│   ├── config.sh         ← config.json management
│   ├── port.sh           ← Find free ports
│   ├── compose.sh        ← docker-compose management
│   ├── hosts.sh          ← /etc/hosts management
│   └── db.sh             ← Database operations
├── drivers/
│   ├── wordpress.sh      ← WordPress + WP-CLI
│   ├── laravel.sh        ← (In progress)
│   └── yii.sh            ← (In progress)
├── config/
│   ├── php.ini
│   └── init-db.sql
└── sites/                ← Site config files (not gitignored)
    └── myblog/
        └── config.json
```

## Base Services

| Service  | URL                 | Description          |
|----------|---------------------|----------------------|
| Proxy    | -                   | nginx reverse proxy  |
| MySQL    | Port 3306           | Shared database      |
| Adminer  | http://adminer.test | Database management  |
| MailHog  | http://mail.test    | Test email service   |

## Adding a New Driver

1. Create a file `drivers/mytype.sh`
2. Implement three functions:
   - `driver_mytype_compose_service()`
   - `driver_mytype_post_install()`
   - `driver_mytype_info()`
3. Usage: `pdev site add --name mysite --type mytype`
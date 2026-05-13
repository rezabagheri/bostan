# Bostan

[![Status](https://img.shields.io/badge/status-early%20development-orange)](#roadmap)
[![Go](https://img.shields.io/badge/Go-1.26%2B-00ADD8?logo=go)](https://go.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Your local development garden. Plant, grow, and harvest sites locally.

> [!WARNING]
> **Early development.** This README documents the planned product. Most
> features are not yet implemented and the CLI is not yet usable. Star or
> watch this repository to follow progress.

**Bostan** (Persian: بوستان, "garden") is a Docker-based local development
environment manager. Each site runs in its own isolated container with shared
infrastructure (MySQL, reverse proxy, mail catcher, database UI).

## Highlights

- **Isolated containers** per site — different runtimes, no conflicts.
- **Shared infrastructure** — one MySQL, one proxy, one mail catcher serves all sites.
- **Single static binary** — no runtime dependencies. Download and run.

## Requirements

- Docker Desktop or Docker Engine with Compose v2
- macOS (Intel or Apple Silicon) or Linux
- Windows: WSL2 recommended

## Installation

> Coming soon — see the [releases page](../../releases) once the first
> release is published.

## Quick Start

> Coming soon.

## Roadmap

Bostan is built progressively. Current status:

- [x] Project skeleton (Go module, layout, tooling)
- [ ] CLI command framework (Cobra)
- [ ] Core types and configuration files
- [ ] Docker integration via the official Go SDK
- [ ] WordPress site driver
- [ ] Database operations (create, drop, backup, restore)
- [ ] `/etc/hosts` management
- [ ] Site lifecycle commands (`up`, `down`, `delete`, `clone`)
- [ ] Laravel and other site drivers
- [ ] HTTP API
- [ ] Embedded web UI
- [ ] Distribution: GoReleaser, Homebrew tap, install script
- [ ] Remote/live site management

## Contributing

Contributions are welcome. Please open an issue to discuss substantial
changes before implementing them.

## License

[MIT](LICENSE) © 2026 Reza Bagheri and contributors

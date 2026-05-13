# CLAUDE.md

This file provides guidance to Claude Code (claude.com/code) and other AI
assistants when working with this repository.

## Project Overview

**Bostan** is a Docker-based local development environment manager, similar
in spirit to Laravel Valet but using per-site containers for stronger
isolation. The name comes from the Persian word for "garden", evoking the
metaphor of growing sites locally.

The end goal is a single static binary that ships both a CLI and an embedded
web UI, capable of managing local development sites and (eventually) remote
live sites.

## Status

Early development. The project is being built progressively. Production use
is not yet supported.

## Stack

- **Language:** Go 1.26+
- **Container runtime:** Docker, via the official Docker SDK for Go
- **CLI framework:** Cobra (planned, not yet integrated)
- **Database access:** `database/sql` with a MySQL driver (planned)
- **HTTP API and Web UI:** standard library `net/http` plus `embed.FS`
  (planned)
- **Distribution:** Single static binary built and published via GoReleaser
  (planned)

## Repository Conventions

### Language

All committed content — code, comments, commit messages, documentation,
issue templates, and user-facing strings — is in English. User-facing
strings used by the CLI should live in a single package so they can be
moved to an i18n library later without disturbing call sites.

### Code Style

- Follow `gofmt` (run automatically on save by the recommended VS Code
  settings in `.vscode/settings.json`).
- Follow the standard [Effective Go](https://go.dev/doc/effective_go) guide
  and the [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
  wiki.
- Every exported identifier (capitalized name) must have a godoc comment
  that begins with the identifier name itself:

  ```go
  // Site represents a managed development site.
  type Site struct { /* ... */ }
  ```

- Linting will be enforced by `golangci-lint` with the configuration in
  `.golangci.yml` once added.

### Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<optional body>
```

- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `build`, `ci`,
  `perf`.
- Scopes (current): `cli`, `core`, `docker`, `db`, `hosts`, `api`, `web`,
  `build`, `ci`.

## Project Layout

```
cmd/bostan/         CLI entry point (main package)
internal/           Private packages (added as needed)
```

The layout starts minimal. New top-level directories are added only when
they have concrete content; empty placeholder directories are avoided.

## Development

```bash
go run ./cmd/bostan              # Run from source
go build -o bostan ./cmd/bostan  # Produce a local binary
go test ./...                    # Run all tests
gofmt -l .                       # List files needing reformatting (empty if clean)
```

## Things to Avoid

- **Do not** shell out to `docker`, `docker compose`, or `mysql` clients
  when an official Go SDK is available. Subprocess calls are reserved for
  cases without a viable SDK.
- **Do not** add dependencies casually. A small dependency footprint is a
  project goal; prefer the standard library or a short hand-written helper.
- **Do not** create files outside the established layout without
  documenting the rationale either in this file or in a note under `docs/`.
- **Do not** restore code from the `prototype/bash-python` branch. That
  branch exists for historical reference only.

## Legacy

The original prototype (Bash + Python) lives on the
`prototype/bash-python` branch as a historical reference. The Go rewrite
started on `main` from a clean slate.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`dbb` is a CRUD API generator that provides a schema-driven datasource. Instead of creating individual controllers, you 
define schemas in a JSON config file and the system automatically generates CRUD endpoints.

Its created on Elixir with Phoenix using Ecto as database manager, with a basic dynamic frontend using Phoenix LiveView

On initial state its a dockerized application that needs to start the server using `make up` and in another terminal
can perform the other commands because on first terminal must keep there to see the logs of the platform

On production usage its using the docker image, create and define the file on the config of the container and start
using it

## Development Setup

### Prerequisites
- Docker with Compose
- Make

### Quick Start
```bash
make              # Download deps, compile code and create docker image
make up-headless  # Start app (http://localhost:4000) + PostgreSQL
make iex          # Open IEx shell inside container
make bash         # Open shell inside container
```

### Testing
```bash
make testing                                    # Run all tests in container
make test_single_file FILE=test/path_test.exs   # Run specific test file
```

### Common Commands (run inside container)
```bash
mix phx.routes                # List all routes
mix ecto.migrate              # Run migrations
mix ecto.rollback             # Rollback migrations
mix run priv/repo/seeds.exs   # Seed database
mix dbb.seed 10               # Generate 10 random records
mix format                    # Runs the code formatter
```

## Architecture

### Core Layers

```
┌─────────────────────────────────────────────────────────────┐
│ DbbWeb (Phoenix)                                            │
│ ├── Controllers: table_controller.ex (dynamic CRUD)         │
│ ├── LiveViews: admin/user management, setup                 │
│ └── Components: layouts, core_components                    │
├─────────────────────────────────────────────────────────────┤
│ Dbb.SchemaManager                                           │
│ ├── table_handler.ex  - Schema field/validation logic       │
│ └── table_api.ex      - CRUD operation interfaces           │
├─────────────────────────────────────────────────────────────┤
│ Dbb (Domain)                                                │
│ ├── content/          - Schema-defined tables               │
│ ├── accounts/         - User auth (Guardian + bcrypt)       │
│ ├── cache.ex          - Runtime schema cache                │
│ └── repo.ex           - Ecto repo                           │
└─────────────────────────────────────────────────────────────┘
```

### Key Modules

- **Dbb.Content.Table** - Dynamically created tables from `config.json` schemas
- **Dbb.SchemaManager** - Handles schema parsing, validation, and table operations
- **Dbb.Cache** - Caches schema definitions at runtime
- **Dbb.Accounts.Guardian** - JWT-based authentication
- **DbbWeb.Plugs** - `basic_api_auth.ex` and `basic_browser_auth.ex` for route protection

### Schema Config Structure

Schemas are defined in `config.json` (or file specified by `CONFIG_SCHEMA` env var):

```json
{
  "schemas": [{
    "name": "users",
    "fields": { "name": "string", "age": "number" },
    "relations": { "product_id:mandatory": "products" },
    "hooks": [{ "events": ["create"], "url": "...", "method": "post" }]
  }]
}
```

Field types: `string`, `number`, `boolean`, `date`, `time`, `datetime`, `uuid`, `array`, `list`

### API Endpoints

Auto-generated per schema:
- `GET /api/v1/:schema` - List (supports `?q=field:value`, `?page=0&count=20`, `?relations=...`)
- `GET /api/v1/:schema/:id` - Show single record
- `POST /api/v1/:schema` - Create
- `PUT /api/v1/:schema/:id` - Update
- `DELETE /api/v1/:schema/:id` - Delete

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CONFIG_SCHEMA` | Yes | - | Path to schema JSON file |
| `POSTGRES_USERNAME` | Yes | postgres | DB username |
| `POSTGRES_PASSWORD` | Yes | postgres | DB password |
| `POSTGRES_HOSTNAME` | Yes | postgres | DB host (use container name in Docker) |
| `POSTGRES_DATABASE` | Yes | postgres | DB name |
| `ALLOWED_SITES` | Prod only | * | CORS origins (comma-separated) |
| `PHX_SERVER` | Prod only | - | Enable Phoenix server |
| `SECRET_KEY_BASE` | Prod only | - | Run `mix phx.gen.secret` |
| `PHX_HOST` | Prod only | example.com | Domain |
| `ADMIN_AUTH_USERNAME` | Optional | - | Basic auth username |
| `ADMIN_AUTH_PASSWORD` | Optional | - | Basic auth password |
| `ALLOWED_API_KEY` | Optional | - | Static API key |
| `POOL_SIZE` | Optional | 10 | DB connection pool size |

### Config Files

- `config/config.exs` - Base config (endpoint, esbuild, tailwind, logger)
- `config/runtime.exs` - Runtime env var loading (prod secrets)
- `config/dev.exs` - Dev settings (code reload, watchers, debug)
- `config/test.exs` - Test config (sandbox pool, mocked HTTP)

## Testing

Tests use Ecto sandbox for isolation. The `test/support` directory contains helpers.

```bash
# in case that containers are down, otherwise ignore
make up

# to enter inside the container and following commands must be runned inside container
make bash

# Run tests
mix test

# Run with coverage
mix test --cover

# Run single test
mix test test/dbb/content_test.exs
mix test test/dbb_web/controllers/api/table_controller_test.exs:25  # by line
```

## Docker

### Development
```bash
make image        # Build dev image (nicolkill/dbb_dev:latest)
make up           # Start docker-compose (app + postgres)
```

### Production
```bash
make hub_image    # Build prod image (nicolkill/dbb:latest)
```

See `docker-compose.yml` for service configuration. The prod image serves HTTPS on port 443.

## Admin UI

1. Navigate to `/admin/setup` and click "Start" to create default admin user
2. Login at `/login` with `admin@admin.com` / `pass`
3. Manage users and permissions from the admin dashboard

## Swagger

API documentation available at `/api_docs/v1` (generated via `phoenix_swagger`).

## Contexts
- [roadmap](./roadmap.md)
- [core](./.claude/contexts/core.md)
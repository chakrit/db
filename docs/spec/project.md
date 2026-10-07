# Project structure and execution

Status: implemented

This repository gives developers explicit Make commands for host-installed local
services. It contains launch recipes rather than a database server implementation,
package installer, container stack, or service supervisor.

## Entry point and dependencies

The root [Makefile](../../Makefile) includes every `make/*.mk` file. Recipes assume
execution from the repository root; relative data and configuration paths use that
working directory. Service behavior is detailed in [services.md](services.md).

Each service depends on executables already available to the shell. The repository
does not pin service versions, install dependencies, or check binary compatibility.
There is no Ruby version pin or Gemfile in this checkout. There is no application build
or automated test suite.

The Makefile declares `.PHONY: *`; it does not enumerate the service targets as phony.
Recipes have no common readiness check, process registry, or failure-recovery mechanism.
Backgrounding a command does not establish that its service is ready.

## Files and data ownership

| Path                       | Role                                                      |
| -------------------------- | --------------------------------------------------------- |
| `make/*.mk`                | Service-specific Make recipes                             |
| `scripts/mysql-logs.sql`   | Template for enabling MySQL general-query logging         |
| `data/pg/`                 | PostgreSQL data and the pg target's log                   |
| `data/mysql/`              | MySQL data and general-query log                          |
| `config/redis.conf`        | Tracked Redis configuration outside disposable data       |
| `data/redis/`              | Redis persistence directory selected by that config       |
| `data/typesense/`          | Typesense data directory                                  |
| `docs/spec/`               | Authoritative project behavior and intended changes       |

`data/.gitignore` ignores generated contents of the service data root while retaining
the ignore file itself. Existing PostgreSQL and Redis directories were moved into
`data/pg/` and `data/redis/`; the recipes now address these paths. Redis configuration
was moved separately to `config/redis.conf`, outside the disposable data directory.
Empty per-service directories are local scaffolding and are not tracked by Git.
[.gitignore](../../.gitignore) retains the legacy root-level ignore patterns.
No recipe creates or selects a repository-owned Mailcatcher data directory yet.
The complete intended layout is defined in [service-lifecycle.md](service-lifecycle.md).

The [README](../../README.md) describes containing service data in this checkout.
Implemented recipes specify data directories for the database and search services,
but do not isolate every service's sockets, ports, logs, or configuration from host
defaults. The README's cleanup examples are destructive; agents must not execute them.

## Working rules

Leave service startup to the user. Preserve existing data; initialization is not an
upgrade or migration procedure. Remote-access configuration must bind to `0.0.0.0`
and use an assigned port in 8000–9000; obtain the port from the control agent before
putting a value into configuration, documentation, or code.

Keep each service's recipes in its existing `make/*.mk` owner. Use the `gh` remote,
and do not push without explicit authorization. Load `architect` and `code` for coding
tasks. ACE is optional tooling; repository commands and durable docs stand on their own.

## Verification limits

This specification records source behavior, not a successful service execution on the
current machine. No service was started or stopped to produce it. Binary versions,
existing data, service reachability, and runtime compatibility have not been verified.

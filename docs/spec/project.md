# Project structure and execution

Status: implemented

This repository gives developers explicit GNU Make commands for host-installed local
services. There is only one instance of each service on the entire machine, always
started through this repository. It contains service recipes rather than an installer,
container stack or persistent service manager.

## Entry point and configuration

The root [Makefile](../../Makefile) loads tracked [.env](../../.env), optional ignored
`.env.local`, then explicit `make/*.mk` owners. Bare Make lists commands and starts
nothing. Run commands from the repository root; `DB_ROOT` is that absolute directory.

`DB_DATA_ROOT` and `DB_CONFIG_ROOT` default to `data/` and `config/` beneath that
root. Settings use conditional defaults. Make command-line values win over
`.env.local`, which wins over inherited environment values and then defaults.
Only the selected service's recipe variables and common `DB_*` values are explicitly
exported. Existing inherited environment variables remain available to subprocesses.

Each service Makefile orders binaries, paths, listener settings and credentials,
followed by init, foreground run, background start, stop and status. Targets are
enumerated in `.PHONY`; aliases for the former command vocabulary are removed.

## Source and data ownership

| Path                    | Role                                                   |
| ----------------------- | ------------------------------------------------------ |
| `make/*.mk`             | One service's variables and Make targets               |
| `scripts/<service>.sh`  | Native initialization, execution and control           |
| `scripts/service.sh`    | Validation, readiness and explicit process control     |
| `config/redis.conf`     | Tracked Redis persistence template                     |
| `data/<service>/`       | Disposable service state, logs and generated config    |
| `docs/spec/`            | Authoritative behavior and operational references      |

MariaDB replaces MySQL and Garage supplies S3-compatible object storage. Active directory
names are `pg`, `mariadb`, `redis`, `mailcatcher`, `typesense`, `garage` and `rabbitmq`.
Existing MySQL data is retained without conversion. PostgreSQL and Redis data was moved
under `data/` without modifying its contents.

`data/.gitignore` keeps generated state untracked. Configuration templates remain
outside disposable state; private generated configuration remains inside each service
directory. All scripts preserve existing data. Initialization is not an upgrade.

## Prerequisites and verification

The user installs native service binaries. A missing executable gives
an actionable error. The repository does not install dependencies, register system
services, or run an automatic upgrade.

The project is exempt from test requirements. Do not write or retain test code, add
automated check/test targets, or run test/check workflows. Leave initialization and
service startup to the user.

Network listeners use assigned ports in 8000–9000; obtain assignments from the control
agent before setting defaults. MariaDB can run through its Unix socket with no TCP
listener while assignments are pending. See [services.md](services.md) for commands
and [modernization.md](modernization.md) for version baselines and verification limits.

Use the current branch and `gh` remote; local commits are authorized, pushes require
explicit permission. Repository commands and docs work without ACE or any agent vendor.

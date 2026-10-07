# Service modernization and release baselines

Status: implemented

This reference records the repository's command/configuration structure and the upstream
interfaces checked for modernization. Source implementation is complete; native runtime
compatibility remains subject to the user-run checks in [services.md](services.md).

## Service choices and lifecycle

Use MariaDB for SQL workloads previously served by the MySQL recipes. Use Garage for
S3-compatible object storage. The repository runs one instance of each service on the
entire machine, always started here; checkout-specific isolation is unnecessary.

All seven services provide init, foreground run, background start, stop and status.
Background processes start only through an explicit start task. They have visible logs
and status/stop commands; no system service is registered. Initialization preserves data
and does not migrate existing databases. See [service-lifecycle.md](service-lifecycle.md).

## Configuration structure

The root Makefile owns configuration loading and explicit includes. Service Makefiles
own their binaries, paths, listener settings, credentials and task definitions in that
order. Defaults use `?=`; personal `.env.local` overrides use normal assignments.
Precedence is command line, then local overrides, inherited environment, then defaults.

Prefixes are `DB_`, `PG_`, `MARIADB_`, `REDIS_`, `MAILCATCHER_`, `TYPESENSE_`,
`GARAGE_` and `RABBITMQ_`. Common roots are absolute; individual path overrides
must be absolute. Scripts quote paths and map configuration to the vendor's documented
surface. Native daemon/control commands are used where available; the shared process
helper captures PID/logs for servers run directly.

State, operational files and generated private configuration live under
`data/<service>/`. Tracked templates remain under `config/`. The previous literal
Typesense credential is removed from recipes; historical Git content is unchanged.
Real credentials must not be committed. If committed secrets are ever required, use
git-crypt and verify encrypted staged blobs.

## Ports and credentials

No numeric listener defaults are selected without control-agent assignments.
Client-facing listeners bind to `0.0.0.0` and use assigned ports in 8000–9000.
Internal Garage RPC, Typesense peering and RabbitMQ distribution listeners are
configured explicitly as well. MariaDB's unset TCP port selects Unix-socket-only mode.

Fresh PostgreSQL init uses SCRAM and a supplied password. Existing PostgreSQL
authentication remains unchanged and requires user review before remote access.
Redis requires a password, Typesense an API key, and RabbitMQ an authenticated
development account. MariaDB initializes authenticated local socket accounts and
offers an explicit remote-account bootstrap task. Garage generates private local keys.

## Checked versions

Checked 2026-10-07. These are documentation/interface baselines, not package locks or
successful end-to-end compatibility measurements.

| Service      | Baseline | Evidence                                                                      |
| ------------ | -------- | ----------------------------------------------------------------------------- |
| PostgreSQL   | 18.6     | [Official stable releases](https://www.postgresql.org/)                       |
| MariaDB      | 13.0.2   | Installed Homebrew arm64 server/client version output                         |
| Redis        | 8.10.2   | [Official source releases](https://download.redis.io/releases/)               |
| MailCatcher  | 0.10.0   | [Upstream releases](https://github.com/sj26/mailcatcher/releases)             |
| Typesense    | 30.2     | [Upstream release](https://github.com/typesense/typesense/releases/tag/v30.2) |
| Garage       | 2.4.1    | [Release builds](https://garagehq.deuxfleurs.fr/_releases.html)               |
| RabbitMQ     | 4.3.6    | [Release information](https://www.rabbitmq.com/release-information)           |

The user installs and upgrades native packages; Make never installs or enables a host
service. Recheck stable release information and upstream data-format requirements when
upgrading. PostgreSQL compares its server/data major version before starting. Do not
treat a changed executable as a data migration, including MySQL-to-MariaDB conversion.
RabbitMQ also requires an Erlang version from the
[compatibility matrix](https://www.rabbitmq.com/docs/which-erlang).

## Verification boundaries

This project is exempt from test requirements; no test code or automated check/test
targets are retained, and agents must not run test/check workflows.
MariaDB's installed version was read without starting a server.
No native service was initialized, started or stopped by the agent.

Network ports still need control-agent assignments. User-run verification covers
foreground interruption, background readiness, stop, restart/persistence, fresh init
after deliberate directory removal, and application-level operations. See
[mariadb.md](mariadb.md), [garage.md](garage.md) and [services.md](services.md).

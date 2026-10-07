# Local services

Explicit commands for host-installed PostgreSQL, MariaDB, Redis, MailCatcher, Typesense,
Garage and RabbitMQ. There is one instance of each service on the machine, always
started through this repository. Nothing starts automatically or registers a system
service.

## MariaDB now

With MariaDB installed and its executables on PATH:

```sh
make mariadb-init
make mariadb-run
```

The server stays in the foreground; Ctrl-C stops it. For an explicit background run:

```sh
make mariadb-start
make mariadb-status
make mariadb-shell
make mariadb-stop
```

The default MariaDB connection is a local Unix socket with OS-user authentication.
No TCP port or password setup is needed for that workflow. Initialization keeps all
database files under `data/mariadb/` and never starts a persistent server. Existing
`data/mysql/` is preserved; it is not a MariaDB migration.

The [MariaDB reference](docs/spec/mariadb.md) covers remote account bootstrap, query
logging and exact paths.

## Shared tasks

Run Make from the repository root. Bare `make` lists commands and starts nothing.

| Task                 | Behavior                                             |
| -------------------- | ---------------------------------------------------- |
| `<service>-init`     | Prepare directories and required initial state       |
| `<service>-run`      | Run in the foreground; interrupt with Ctrl-C         |
| `<service>-start`    | Start in the background and wait for readiness       |
| `<service>-stop`     | Stop the service, keeping its data                   |
| `<service>-status`   | Check whether the service is ready                   |

Service names are `pg`, `mariadb`, `redis`, `mailcatcher`, `typesense`, `garage`, and
`rabbitmq`. The previous bare service starts, `mc`/`ts` aliases and `mysql-*` targets
have been replaced by this vocabulary.

## Configuration

`.env` contains shared Make-compatible defaults. Service-specific defaults live in
their `make/*.mk` owner, grouped as binaries, paths, listeners, then credentials.
Use ignored `.env.local` for personal overrides. Precedence is Make command-line
assignments, then `.env.local`, then inherited environment values, then defaults.

These are Make files, not shell scripts: do not `source` them. Use `NAME = value` in
`.env.local`; quotes become part of a Make value, `#` starts a comment, and a literal
dollar sign must be written as `$$`. Paths containing spaces are supported; use absolute
paths when overriding a directory.

Network ports are deliberately unset until assigned by the control agent. Set each
required `*_PORT` in `.env.local` after assignment; client-facing listeners must use
8000–9000 and bind to `0.0.0.0`. Missing ports fail clearly instead of silently using
an unassigned listener. MariaDB's empty port explicitly selects Unix-socket-only mode.

For a new PostgreSQL cluster, set `PG_PASSWORD`; Redis requires `REDIS_PASSWORD`,
Typesense requires `TYPESENSE_API_KEY`, and RabbitMQ requires `RABBITMQ_PASSWORD`.
Garage generates private local S3 credentials on initialization. No real credential is
provided in tracked defaults.

## Data and upgrades

Each service owns `data/<service>/`, including generated configuration, logs and
operational files. Tracked templates remain under `config/`. MailCatcher's messages
are in memory and disappear when it stops.

To reset a service, stop it, remove its complete data directory yourself, then run
its init and run/start tasks. There is no destructive cleanup target. Initialization
does not migrate an existing database or silently recreate populated state.

Install and upgrade host binaries yourself; these recipes neither install packages nor
enable background package-manager services. PostgreSQL refuses a server/data major
version mismatch. Other services still require their upstream upgrade procedures;
changing an executable is not a data migration.

## References

- [Service command reference](docs/spec/services.md)
- [Configuration and current release baselines](docs/spec/modernization.md)
- [Garage S3 quick reference](docs/spec/garage.md)
- [Required lifecycle](docs/spec/service-lifecycle.md)

This project has no test code or automated check/test targets. Native initialization
and server startup are left to the user.

## License

WTFPL.

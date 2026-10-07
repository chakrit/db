# Existing service commands

Status: implemented

This is the implemented command surface for developers maintaining the local service
recipes. Commands are described from source; they have not been run for this review.
All paths assume the repository root as the working directory.

## PostgreSQL

Source: [make/pg.mk](../../make/pg.mk).

The file exports `LC_ALL=en_US.UTF-8` and `LANG=en_US.UTF-8` for recipe processes.
`PG_FOLDER` is `./pg`; `PG_OPTS` selects it with `-D`, and `PG_LOG_OPTS` selects
`./pg/postgres.log` with `-l`.

| Target      | Recipe behavior                                                 |
| ----------- | --------------------------------------------------------------- |
| `pg-init`   | Creates the directory with mkdir, then invokes initdb with -D   |
| `pg-run`    | Invokes postgres directly with -D                               |
| `pg`        | Invokes pg_ctl start with the data directory and log path       |
| `pg-stop`   | Invokes pg_ctl stop with the same data directory and log path   |

Initialization has no guard for an existing cluster. No port, listen address,
authentication policy, or explicit shutdown mode is set in the recipe. The repository
does not provide a PostgreSQL configuration file or a major-version data migration.

## MySQL

Sources: [make/mysql.mk](../../make/mysql.mk) and
[scripts/mysql-logs.sql](../../scripts/mysql-logs.sql).

`MYSQL_FOLDER` is the absolute path of `./mysql`, and `MYSQL_LOGFILE` is its
`queries.log`. The base directory is inferred with `which mysql_install_db`, readlink,
and dirname; the code assumes an installation layout rather than accepting an explicit
binary prefix as its default.

`MYSQL_OPTS` supplies `--datadir`, `--basedir`, and `--user=$(whoami)`. The last expression
is a Make variable reference named `whoami`, not a shell invocation; without a supplied
Make variable it expands to an empty value. The recipe does not compute the current OS
user. `MYSQL_DB` defaults to the quoted text `'root'` and is used as a database name in
the logging template, separately from the client's root login.

| Target         | Recipe behavior                                                 |
| -------------- | --------------------------------------------------------------- |
| `mysql-init`   | Invokes mysql_install_db with MYSQL_OPTS                        |
| `mysql-run`    | Invokes mysqld directly with MYSQL_OPTS                         |
| `mysql`        | Invokes mysqld with MYSQL_OPTS and backgrounds it with &        |
| `mysql-stop`   | Invokes sudo mysqladmin shutdown                                |
| `mysql-logs`   | Expands the SQL with m4, pipes it to mysql -u root, follows log |

The logging SQL selects `MYSQL_DB`, sets global `log_output` to `FILE`, sets the global
general-log path, and enables the global general log. A failed `USE` statement can
prevent the subsequent statements from running. There is no corresponding disable
target. The final log-following command is `tail -f`; the target is long-running.

The clients do not receive an explicit socket, host, port, or isolated option file.
Stopping and enabling logging therefore do not explicitly identify the server launched
with the repository data directory. `mysql-stop` adds sudo but no database credentials.
The pipeline has no explicit pipefail handling; upstream command failure is not
independently propagated by the recipe. There is no current-version compatibility check,
readiness check, or data migration.

## Redis

Sources: [make/redis.mk](../../make/redis.mk) and
[redis/redis.conf](../../redis/redis.conf).

`REDIS_OPTS` names `./redis/redis.conf`. `REDIS_FOLDER` is defined as `./redis` but is
not used by the recipes. The config selects `dir ./redis`, `rdbcompression yes`,
`appendonly yes`, and `appendfsync everysec`; other settings are left to the executable's
defaults.

| Target         | Recipe behavior                                               |
| -------------- | ------------------------------------------------------------- |
| `redis-run`    | Invokes redis-server with the repository config               |
| `redis`        | Invokes the same command and backgrounds it with &            |
| `redis-stop`   | Invokes redis-cli SHUTDOWN using default connection settings  |

There is no `redis-init` target despite the README example. The configuration is tracked
inside the ignored data directory. No bind address, port, credentials, PID file, or
repository-specific shutdown connection is supplied. Persistence is enabled, but these
recipes do not verify saved data or provide a data-format migration.

## Mailcatcher

Source: [make/mailcatcher.mk](../../make/mailcatcher.mk).

| Target          | Recipe behavior                                             |
| --------------- | ----------------------------------------------------------- |
| `mc-run`        | Invokes mailcatcher --foreground                            |
| `mc`            | Invokes mailcatcher without command options                 |
| `mailcatcher`   | Requests mc as an order-only prerequisite; has no recipe    |
| `mc-stop`       | Sends curl -v -X DELETE to http://0.0.0.0:1080              |

The startup recipes do not explicitly set SMTP or web bind addresses or ports. The stop
recipe hardcodes the HTTP destination and does not add curl's fail-on-HTTP-error option.
Its source establishes that a DELETE request is sent; whether a particular installed
Mailcatcher version shuts down successfully has not been verified. No initialization,
repository data path, or pinned gem dependency is provided.

## Typesense

Source: [make/typesense.mk](../../make/typesense.mk).

`TS_FOLDER` is `./ts`. `TS_OPTS` supplies `--data-dir` and `--api-key`; `TS_KEY` has a
literal value committed in the recipe. The value is not reproduced here. These variables
use ordinary Make assignments and can be overridden on the Make command line.

| Target        | Recipe behavior                                              |
| ------------- | ------------------------------------------------------------ |
| `ts`          | Invokes typesense-server directly with TS_OPTS               |
| `typesense`   | Requests ts as an order-only prerequisite; has no recipe     |

No recipe creates `./ts`, starts a background instance, stops an instance, or checks
readiness. Bind addresses and ports are not explicitly configured. Real credentials
require git-crypt protection; removing a value later does not undo historical exposure.

## Missing services and runtime guarantees

There are no MinIO or RabbitMQ recipes or configuration files. Existing MySQL recipes
establish an intended MySQL command surface, not compatibility with modern MySQL.

No service is pinned to a release. Initialization, start, foreground execution, shutdown,
and logging are inconsistent across services. No shared recipe verifies binary presence,
service identity, exit status after background startup, or end-to-end runtime readiness.

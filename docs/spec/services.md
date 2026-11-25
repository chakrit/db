# Service commands

Status: implemented

Run commands from the repository root. Native binaries must already be on PATH.
Make variables exist solely to avoid repeating paths and command options.

All services use `<service>-init`, `<service>-run` for foreground execution,
`<service>` for explicit background execution, and `<service>-stop`.
Ports are the native defaults; preview-server assignment rules do not apply.

## PostgreSQL

[make/pg.mk](../../make/pg.mk) uses `initdb`, `postgres` and `pg_ctl`.
Data is `./data/pg`; the background log is `postgres.log` in that directory.
A completed cluster is retained on repeat initialization. The default port is 5432.
Authentication and upgrade behavior follow the installed PostgreSQL server.

## MariaDB

[make/mariadb.mk](../../make/mariadb.mk) uses `mariadb-install-db`, `mariadbd`,
`mariadb` and `mariadb-admin`. Data is `./data/mariadb/db`; the socket, PID,
logs and temporary directory are under `./data/mariadb`. The default TCP port is 3306.

Initialization uses native Unix-socket authentication for the current OS user.
Background execution captures output in `server.log`. The existing query-log task
is `mariadb-logs`. See [mariadb.md](mariadb.md).

## Redis

[make/redis.mk](../../make/redis.mk) uses `redis-server` and `redis-cli`.
[config/redis.conf](../../config/redis.conf) fixes persistence under `./data/redis`,
with RDB compression and AOF fsync every second. The default port is 6379.
Background execution uses native daemonization; shutdown uses the default Redis client.

## MailCatcher

[make/mailcatcher.mk](../../make/mailcatcher.mk) uses native foreground execution in
both modes; background output is captured under `./data/mailcatcher`.
Native temporary files are directed to its `tmp/` directory.
Defaults are SMTP 1025 and HTTP 1080. Stop uses MailCatcher's native HTTP DELETE.
Captured messages are in memory and disappear on shutdown.

## Typesense

[make/typesense.mk](../../make/typesense.mk) starts the native server with data under
`./data/typesense` and the fixed API key `local-development`.
Native defaults are API 8108 and peering 8107. Background mode captures PID/output
under the data directory; stop sends SIGTERM to that PID.

## Garage

[make/garage.mk](../../make/garage.mk) uses a native single-node Garage server and
[config/garage.toml](../../config/garage.toml). SQLite metadata and blocks live under
`./data/garage`. The standard quick-start endpoints are S3 3900 and RPC 3901.
Native key/bucket administration is documented in [garage.md](garage.md).

## RabbitMQ

[make/rabbitmq.mk](../../make/rabbitmq.mk) uses native foreground and detached server
execution. Its native environment options redirect database, logs, PID, plugin state,
cookie and temporary files under `./data/rabbitmq`; they do not expose a configurable
framework. Accounts and ports use native defaults, including AMQP 5672.

Stop uses `rabbitmqctl shutdown`, then asks the native `epmd` helper to stop.
If the broker already exited after a foreground run, stop an idle helper with
`epmd -kill`; that command refuses while another Erlang node remains registered.

No service was started to produce this reference. No test/check workflow is provided.

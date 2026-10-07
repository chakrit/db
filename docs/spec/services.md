# Service commands

Status: implemented

This reference is for developers operating the repository's native service recipes.
Commands have been checked from source, shell syntax, ShellCheck and Make dry-runs;
no real service was started for verification.

Run Make from the repository root. Every service has `-init`, `-run`, `-start`,
`-stop` and `-status` targets. Run remains in the foreground; start explicitly
launches a background process and checks readiness. Stop preserves data.

## Configuration and prerequisites

Executable overrides use `*_SERVER_BIN`, `*_CLIENT_BIN`, and native control/init
binary settings where appropriate. All paths default beneath `DB_DATA_ROOT` or
`DB_CONFIG_ROOT`. Service variables are exported only to that service's targets.

Set assigned network ports and private credentials in `.env.local`. No listener
port is guessed. MariaDB with an empty `MARIADB_PORT` is explicitly socket-only.
Service binaries are installed by the user; Make does not install or upgrade them.

## PostgreSQL

Owner: [make/pg.mk](../../make/pg.mk), [scripts/pg.sh](../../scripts/pg.sh).

Data is `data/pg/`; its socket directory and background log are inside that directory.
Fresh init uses `initdb` with `PG_USER` and `PG_PASSWORD`, UTF-8 and SCRAM
authentication. Existing complete clusters are retained and their authentication is
not changed. Check existing `pg_hba.conf` before enabling remote access.

Foreground uses `postgres`; background uses native `pg_ctl start -w -t 10`.
Stop uses native fast shutdown with a bounded wait; status uses `pg_ctl` and
`pg_isready`. Both run modes require `PG_PORT`. A server/data major-version
mismatch is rejected without changing the cluster.

[initdb](https://www.postgresql.org/docs/current/app-initdb.html),
[pg_ctl](https://www.postgresql.org/docs/current/app-pg-ctl.html).

## MariaDB

Owner: [make/mariadb.mk](../../make/mariadb.mk),
[scripts/mariadb.sh](../../scripts/mariadb.sh).

`mariadb-install-db` initializes `data/mariadb/db/` with Unix-socket authentication
for the current OS user. Operational files live alongside that directory.
Foreground uses `mariadbd --no-defaults`; background invokes that same foreground
command explicitly and captures its PID/log. Readiness executes `SELECT 1` through
the socket; stop uses native `mariadb-admin shutdown`.

Additional targets are `mariadb-shell`, `mariadb-bootstrap` for an authenticated
remote development account, and `mariadb-logs` for general-query logging.
See [mariadb.md](mariadb.md) for the immediate workflow and configuration.
Existing MySQL data is neither reused nor converted.

## Redis

Owner: [make/redis.mk](../../make/redis.mk),
[scripts/redis.sh](../../scripts/redis.sh).

Init prepares `data/redis/` and a private runtime config that includes the tracked
[config/redis.conf](../../config/redis.conf). The native persistence options are RDB
compression and AOF with fsync every second; all generated state stays inside the data
directory. Run/start configure `REDIS_PORT`, `REDIS_HOST` and `REDIS_PASSWORD`.

Foreground uses native daemonization disabled; background uses native daemonization
enabled. Authenticated PING must return PONG for readiness. Stop invokes native
SHUTDOWN. Passwords use generated config and `REDISCLI_AUTH`, not command arguments.

[Redis CLI](https://redis.io/docs/latest/develop/tools/cli/).

## MailCatcher

Owner: [make/mailcatcher.mk](../../make/mailcatcher.mk),
[scripts/mailcatcher.sh](../../scripts/mailcatcher.sh).

Init prepares `data/mailcatcher/` and a temporary directory. Both execution modes
use native `--foreground` with explicit SMTP/HTTP bindings. Background mode captures
the process PID and output; stop sends graceful SIGTERM. Readiness requests the web
interface with a bounded curl timeout. Both assigned ports must differ.

Captured messages use native in-memory storage and disappear on shutdown.
[MailCatcher](https://mailcatcher.me/).

## Typesense

Owner: [make/typesense.mk](../../make/typesense.mk),
[scripts/typesense.sh](../../scripts/typesense.sh).

Init prepares `data/typesense/` and its log directory. Both modes use the native
server command with explicit API and loopback peering listeners. Configure
`TYPESENSE_PORT`, `TYPESENSE_PEERING_PORT` and `TYPESENSE_API_KEY`; the key is
passed through the documented environment variable rather than argv.

Background mode captures the process PID/log; graceful stop uses SIGTERM.
Readiness checks that `/health` returns the successful JSON body.
[Server configuration](https://typesense.org/docs/30.2/api/server-configuration.html).

## Garage

Owner: [make/garage.mk](../../make/garage.mk),
[scripts/garage.sh](../../scripts/garage.sh).

Native single-node storage uses SQLite metadata and filesystem blocks. Init generates
private configuration, RPC credentials and S3 credentials under `data/garage/`.
Configure assigned S3 and RPC ports before init; existing configuration and credentials
are retained on repeat init. First startup bootstraps the default key and bucket.

Background mode captures the server PID/log. Readiness uses native `health --quiet`;
stop sends graceful SIGTERM. See [garage.md](garage.md) for exact settings, credentials,
compatibility limits and upstream references.

## RabbitMQ

Owner: [make/rabbitmq.mk](../../make/rabbitmq.mk),
[scripts/rabbitmq.sh](../../scripts/rabbitmq.sh).

Init prepares private configuration, a cookie and paths under `data/rabbitmq/`.
First server startup creates the native database. Configure assigned AMQP and
distribution ports, and an authenticated development user. Native foreground server
execution and `-detached` background execution share the same node and paths.

Native diagnostics check readiness; `rabbitmqctl` handles graceful stop.
Operational files, plugin expansion and Erlang crash dumps remain under the service
directory. RabbitMQ uses Erlang's native epmd helper; status displays its registrations,
and stop also stops epmd when no Erlang node remains. After interrupting a foreground
broker, run rabbitmq-stop to clean up an idle epmd. Cleanup refuses when another node
is registered. See the script's settings for the precise environment mapping.
[File locations](https://www.rabbitmq.com/docs/relocate),
[CLI](https://www.rabbitmq.com/docs/cli),
[Erlang compatibility](https://www.rabbitmq.com/docs/which-erlang).

## Runtime verification

The user verifies each installed release: init, foreground interruption, background
readiness, status, stop, restart and persistence, then fresh initialization after
removing a stopped service's directory. MailCatcher's messages are intentionally
transient. Exercise application SQL, Redis commands, S3 uploads/downloads, Typesense
search, SMTP capture and AMQP publish/consume as applicable.

No automatic data migration or destructive cleanup task is provided.

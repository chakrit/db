# Service modernization plan

Status: draft

This plan is for maintainers implementing the next revision of the local service
launcher. It proposes changes to recipes and configuration; those changes are not yet
implemented. [service-lifecycle.md](service-lifecycle.md) records the accepted lifecycle
requirements, and [services.md](services.md) records the current command surface.

Research date: 2026-10-07. Recheck exact releases before implementation. No dependency
was installed, host configuration inspected, or service started during planning.

## Acceptance criteria

Every supported service has explicit init, foreground, background, stop, and status
tasks. Foreground execution remains attached to the terminal; background execution
returns only after a bounded readiness check succeeds. There is only one instance of
each service on the entire machine, always started through this repository. Stop and
status tasks use that service's connection settings; checkout-specific instance isolation
is unnecessary. Stopping leaves persisted data intact.

After the user stops a service and removes its data directory, init followed by either
run mode produces a fresh instance. Initialization must reject incompatible or partial
existing state without deleting it. It must not silently reinitialize populated data.
Services with automatic first-boot initialization still get explicit preparation tasks;
document what init prepares and what the server completes on first startup.

Service state, logs, process identity files, sockets, and temporary service files live
under `data/<service>/`. Tracked configuration lives outside disposable data. Every
Makefile follows the same variable order and target order. No installer or service
manager starts an instance implicitly.

## Proposed command surface

Use the service names `pg`, `mysql`, `redis`, `mailcatcher`, `typesense`, `minio`, and
`rabbitmq` consistently in targets and data-directory names. Each service offers:

| Target               | Contract                                                      |
| -------------------- | ------------------------------------------------------------- |
| `<service>-init`     | Prepare directories, configuration and required initial data  |
| `<service>-run`      | Run the service in the foreground                             |
| `<service>-start`    | Run the service in the background and check readiness         |
| `<service>-stop`     | Stop the service and preserve its data                        |
| `<service>-status`   | Report whether the service is ready                           |

Enumerate these targets in `.PHONY`; replace the current `.PHONY: *` declaration.
Set a harmless explicit default target that lists available tasks. Document the rename
from bare service starts and the short `mc`/`ts` names; replace those names rather than
retaining parallel command vocabularies. Keep MySQL logging as a service-specific task
with the same explicit connection settings as its other client operations.

## Configuration and file structure

```text
Makefile                    entry point and explicit includes
.env                        shared non-secret defaults
.env.local                  ignored personal overrides
make/                       one recipe file per service
config/                     tracked service configuration templates
scripts/mysql-logs.sql      existing SQL owner, adapted if still needed
data/.gitignore             keeps generated state out of Git
data/<service>/             disposable instance state
docs/spec/                  behavior and exact command contracts
```

Reuse the root Makefile for configuration loading and shared root-path definitions.
Reuse each service's existing recipe file; add `make/minio.mk` and `make/rabbitmq.mk`
only because no existing owners implement those services. The tracked Redis
configuration already lives in `config/redis.conf`; preserve that separation.
Do not create a generic supervisor or task-generation framework: use supported service
commands and share only a demonstrated common responsibility.

Load `.env` and optional `.env.local` as documented Make-compatible assignments. Shared
defaults use conditional assignments, so supplied environment values survive; personal
overrides use normal assignments. Precedence is Make command-line assignments, then
`.env.local`, then the inherited environment, then `.env` defaults. Do not source the
files as shell scripts. Export only environment variables actually required by the
service being launched, rather than exporting every variable to every subprocess.

Use `DB_ROOT`, `DB_DATA_ROOT`, and `DB_CONFIG_ROOT` for common locations. Use prefixes
`PG_`, `MYSQL_`, `REDIS_`, `MAILCATCHER_`, `TYPESENSE_`, `MINIO_`, and `RABBITMQ_`.
Within every service file, order settings as executable paths, data/config paths,
network settings, authentication settings, then derived command arguments; follow with
init, run, start, stop, and status targets in that order.

Use consistent suffixes such as `_SERVER_BIN`, `_CLIENT_BIN`, `_DATA_DIR`, `_CONFIG_FILE`,
`_LOG_FILE`, `_PID_FILE`, `_HOST`, and `_PORT` where the concepts apply. Multi-listener
services add descriptive names such as `_SMTP_PORT`, `_HTTP_PORT`, or `_CONSOLE_PORT`.
Do not invent meaningless variables to fill a template. Resolve data paths absolutely
and quote paths in commands, including paths containing spaces. Map shared configuration
to vendor environment variables only at the relevant service boundary.

Bind remotely accessible listeners to `0.0.0.0`. Obtain all client-facing ports from
the control agent in the permitted 8000–9000 range before writing actual defaults.
RabbitMQ also needs explicit node-distribution and discovery settings; assess those
separately from its client-facing listeners rather than assuming one port is enough.

Keep real credentials out of public defaults. Personal secrets belong in ignored local
configuration. If secrets must be committed, configure git-crypt, verify protection
patterns and encrypted staged blobs, and handle historical exposure separately. Replace
the current literal Typesense key without copying it into a new public file.

## Existing services and current-release work

**PostgreSQL:** the official site lists 18.6 as its newest stable release and 19 as a
beta. Target stable PostgreSQL, retaining initdb, postgres and pg_ctl; make data,
configuration, listener, log and shutdown behavior explicit. Do not attempt an in-place
major-version migration merely by changing a binary. [Official releases](https://www.postgresql.org/).

**Redis:** target 8.10.2, which is listed in the official source release index. Keep the
tracked config outside the data directory, add init, and use explicit connection details
for readiness and shutdown. Keep all RDB and multi-part AOF state under `data/redis/`.
Check current protected-mode/authentication behavior when enabling remote access.
[Official downloads](https://download.redis.io/releases/).

**Mailcatcher:** the upstream release page marks 0.10.0 as latest. Keep the installed gem
as the host prerequisite without reintroducing a repository Ruby version pin. Verify its
current CLI, runtime dependencies, daemon behavior, shutdown API and error handling.
Init prepares local operational files; do not claim Mailcatcher's captured messages are
durable unless its current public surface supports persistence.
[Upstream releases](https://github.com/sj26/mailcatcher/releases).

**Typesense:** target 30.2, the upstream latest release. Add init, background execution,
bounded readiness, explicit listener settings and shutdown behavior. Check whether its
current public CLI supplies daemon/PID behavior before choosing process control. Do not
invent an unsupported shutdown API or adopt another service manager to fill the gap.
[Latest release](https://github.com/typesense/typesense/releases/latest).

## MySQL support

Existing support uses mysql_install_db and installation-layout inference. Replace it
with modern mysqld initialization, explicit binary/configuration paths, a repository
socket/PID/log/data layout, and clients pointed at that same instance. Fix the Make
variable expression currently used instead of the OS user and remove global sudo-based
shutdown. Replace the unnecessary database selection in logging and check client errors.

Current upstream release notes list the 26.7 series, while the supported-platform matrix
also names 9.7 LTS and 8.4 LTS. Verify the latest stable macOS artifact and its platform
support before choosing the exact tested series; do not silently substitute MariaDB.
[Release notes](https://dev.mysql.com/doc/relnotes/mysql/26.7/en/),
[supported platforms](https://www.mysql.com/support/supportedplatforms/database.html).

Use the current documented `mysqld --initialize` flow and complete credential bootstrap
for remote use. Do not leave a remotely bound root account with an empty password.
Initialization documentation distinguishes generated temporary passwords from
`--initialize-insecure`; the planned default is authenticated initialization.
[Initialization reference](https://dev.mysql.com/doc/refman/9.7/en/data-directory-initialization.html).

## RabbitMQ support

Add native support targeting 4.3.6. The generic UNIX distribution supports macOS,
foreground `rabbitmq-server`, and background `rabbitmq-server -detached`. Check the
current Erlang compatibility matrix and select a supported OTP 27/28 release before
implementation; do not assume the newest OTP is compatible.
[Release information](https://www.rabbitmq.com/release-information),
[generic UNIX distribution](https://www.rabbitmq.com/docs/install-generic-unix),
[Erlang compatibility](https://www.rabbitmq.com/docs/which-erlang).

Init prepares instance configuration and bootstrap settings; first server boot creates
the native database. Route data, logs, PID, plugin expansion, feature flags, enabled
plugins and the authentication cookie explicitly into this checkout's service directory.
Use a stable node name and the same cookie/node identity for all CLI operations. Do not
set RABBITMQ_BASE as a macOS relocation shortcut: upstream marks it Windows-only.
[File locations](https://www.rabbitmq.com/docs/relocate).

Provide a dedicated authenticated development user for remote connections and verify
AMQP publish/consume and optional management access during the user-run runtime check.
Keep any broker-generated state inside the disposable directory, not the user's home.

## MinIO support decision

The community repository was archived on 2026-04-25, states that it is no longer
maintained, and distributes community code as source only. A normal maintained native
binary installation cannot be assumed. [Upstream repository](https://github.com/minio/minio).

Keep MinIO implementation gated on a deliberate distribution choice. Do not silently
replace it with another S3 server or the proprietary AIStor product. If the user accepts
archived community source, pin the chosen revision, audit it before adoption, and obtain
separate approval for any resource-intensive build. Then implement init, foreground,
background, explicit API/console bindings, credentials, readiness and shutdown with
all object-store metadata under `data/minio/`.

## Implementation sequence and checks

1. Obtain listener assignments and resolve exact stable artifacts and executable
   prerequisites without installing or starting host services implicitly. Keep the
   MinIO distribution decision separate so it does not block existing service work.
2. Establish the shared environment loading, variable convention and target vocabulary;
   implement PostgreSQL as the first concrete service using the accepted data layout.
3. Modernize MySQL, Redis, Mailcatcher and Typesense, then add RabbitMQ; each service
   lands only with all required lifecycle tasks.
4. Add MinIO after its distribution decision. Update README examples, instructions and
   existing specs in the same changes as the actual command surface changes.
5. Provide a user-run verification procedure for each supported release: init, foreground
   interruption, background readiness, stop, restart and persistence,
   and fresh init after the user removes the stopped instance directory.

Existing PostgreSQL and Redis directories have been relocated without changing their
data files. Before changing server versions, inspect the relevant repository state,
record server/data-format compatibility, and prepare explicit upgrade instructions.
Never relocate a live database automatically or delete old data to force a fresh start.
Retain old ignore patterns while those directories may still contain user data.

Validate Make composition and environment precedence with stub executables, including
paths with spaces, missing binaries, partial initialization, conflicting ports, startup
failure and client connection settings. Avoid executing the
current Makefile even in dry-run mode for inspection: its shell expansions perform
installation-path probes during evaluation.

Run shellcheck on new shell scripts if any are necessary. Service runtime tests remain
user-run because server startup belongs to the user. Do not raise resource budgets or
timeouts. Document unverified runtime checks rather than declaring compatibility from
source inspection alone. Local commits may follow clean checks; pushing requires
separate authorization.

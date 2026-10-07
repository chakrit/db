# MariaDB

Status: implemented

MariaDB replaces the repository's MySQL tasks. Its installed native binaries reported
version 13.0.2 on 2026-10-07. The implementation uses
[`make/mariadb.mk`](../../make/mariadb.mk),
[`scripts/mariadb.sh`](../../scripts/mariadb.sh), and the shared
[`scripts/service.sh`](../../scripts/service.sh) lifecycle functions.

Run one repository-managed instance per machine. The user starts services; agents do
not start them. No task installs software or registers a system service.

## Local workflow

Run these commands from the repository root. Initialize once:

```sh
make mariadb-init
```

Initialization creates native system tables with Unix socket authentication for the
current operating-system account, alongside MariaDB's native local root account. It
omits the test database. These settings follow the official
[initializer reference](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-install-db).

Choose one execution mode:

```sh
make mariadb-run
```

`mariadb-run` runs the native server in the foreground. Stop it with Ctrl-C, or use
`mariadb-stop` from another terminal. For background execution instead:

```sh
make mariadb-start
```

Background startup records the native process PID and waits for an authenticated local
`SELECT 1`. Each readiness probe has a one-second execution bound; retries use
`DB_WAIT_ATTEMPTS`, which defaults to 10. Startup failure returns an error and identifies
the log file.

While the server runs, use:

```sh
make mariadb-shell
make mariadb-status
```

The shell and administrative commands connect through the repository's Unix socket.
With `MARIADB_USER` empty, they use the current operating-system username. Unix socket
authentication verifies the process's operating-system identity; changing the SQL
username alone does not grant access. See the
[authentication reference](https://mariadb.com/docs/server/reference/plugins/authentication-plugins/authentication-plugin-unix-socket).

Stop either execution mode through authenticated native shutdown:

```sh
make mariadb-stop
```

To enable the general query log and follow it:

```sh
make mariadb-logs
```

This changes the running server's general-log settings. Ending the log follower with
Ctrl-C leaves general logging enabled until changed through SQL or the server restarts.
Query logs contain application SQL and can contain sensitive values.

## Optional remote access

An empty `MARIADB_PORT` explicitly selects Unix-socket-only operation through
`--skip-networking`. Ask the control agent for a port in 8000–9000 before assigning
`MARIADB_PORT`; the default TCP bind address is `0.0.0.0`.

Before enabling TCP, set `MARIADB_REMOTE_USER` and a nonempty
`MARIADB_REMOTE_PASSWORD` in the ignored `.env.local`, then run against the local server:

```sh
make mariadb-bootstrap
```

The default remote username is `dev`; the account exists only after bootstrap. Bootstrap
creates that account at host `%` and grants all privileges on all databases, without a
grant option. The username must contain only letters, digits, or underscores and cannot
be `root`; the password cannot contain newlines. Bootstrap fails if the account already
exists rather than replacing its credentials.

Credentials reach the client through standard input, with session general logging
disabled. Clients used by `mariadb-shell`, `mariadb-bootstrap`, and `mariadb-logs` disable
SQL history through `MYSQL_HISTFILE=/dev/null`. Passwords are not put in command arguments.

After bootstrap, set the assigned `MARIADB_PORT` in `.env.local` and restart the server
using `mariadb-stop` followed by the chosen run or start target. Remote applications use
the machine's reachable address, assigned port, and bootstrapped credentials; the
repository's shell, readiness, and shutdown commands continue using the local socket.

## Configuration and storage

Configuration precedence is Make command-line assignments, then `.env.local`, then the
inherited environment, then `.env` and service defaults. `.env` and `.env.local` use Make
syntax, not shell syntax; do not commit personal credentials. Native invocations put
`--no-defaults` first so MariaDB option files do not override repository settings, as
documented in the
[initializer reference](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-install-db#no-defaults).

| Setting                   | Default or meaning                                  |
| ------------------------- | --------------------------------------------------- |
| `MARIADB_SERVER_BIN`      | `mariadbd`                                          |
| `MARIADB_INIT_BIN`        | `mariadb-install-db`                                |
| `MARIADB_CLIENT_BIN`      | `mariadb`                                           |
| `MARIADB_ADMIN_BIN`       | `mariadb-admin`                                     |
| `MARIADB_DATA_DIR`        | `$(DB_DATA_ROOT)/mariadb`                           |
| `MARIADB_SOCKET`          | `$(MARIADB_DATA_DIR)/server.sock`                   |
| `MARIADB_PID_FILE`        | `$(MARIADB_DATA_DIR)/server.pid`                    |
| `MARIADB_LOG_FILE`        | `$(MARIADB_DATA_DIR)/server.log`                    |
| `MARIADB_QUERY_LOG_FILE`  | `$(MARIADB_DATA_DIR)/queries.log`                   |
| `MARIADB_HOST`            | `0.0.0.0` when TCP is enabled                       |
| `MARIADB_PORT`            | Empty selects socket-only; otherwise assigned port  |
| `MARIADB_USER`            | Empty selects the current operating-system username |
| `MARIADB_REMOTE_USER`     | `dev`, created only by bootstrap                    |
| `MARIADB_REMOTE_PASSWORD` | Empty; bootstrap requires a personal value          |

The actual native datadir is `data/mariadb/db/`; native temporary files use
`data/mariadb/tmp/`. The socket, PID, server log, query log, and `initialized` family
marker live directly under `data/mariadb/`. These paths follow `MARIADB_DATA_DIR` overrides.
Initialization makes the data and temporary directories private to their owner.

Repeated initialization accepts a completed MariaDB directory. Incomplete, unrecognized,
or differently marked data is rejected for inspection. Existing `data/mysql/` remains
untouched; no migration or family conversion occurs automatically.

## Verification boundary

Verification covers official CLI references, installed binary version identification,
shell syntax, ShellCheck, and Make recipe dry-runs. No live initialization, server
startup, authentication, or shutdown has been checked by agents. This project is exempt
from automated-test requirements; do not write or retain test code.

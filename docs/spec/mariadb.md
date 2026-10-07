# MariaDB

Status: implemented

MariaDB replaces MySQL in this repository. Native Homebrew server/client binaries
reported version 13.0.2 on 2026-10-07. [make/mariadb.mk](../../make/mariadb.mk) calls
those binaries directly; Make variables only keep repeated paths and options DRY.

Initialize, then run in the foreground:

```sh
make mariadb-init
make mariadb-run
```

For background execution instead:

```sh
make mariadb
make mariadb-stop
```

The server uses its native TCP port 3306. Local administration uses the repository socket
and the current OS user's native Unix-socket authentication:

```sh
mariadb --socket="$PWD/data/mariadb/server.sock" --user="$(id -un)"
```

State is fixed beneath `./data/mariadb`: native tables in `db/`, temporary files in
`tmp/`, and `server.sock`, `server.pid`, `server.log` and `queries.log` alongside.
Native option files are disabled with `--no-defaults` so they cannot redirect that data.

`mariadb-logs` enables and follows the native general query log. Ending the follower
leaves logging enabled until SQL changes it or the server restarts.

Repeat initialization retains an existing system database. Existing `data/mysql/` is
neither reused nor converted. Upgrade and account administration use native MariaDB tools;
there is no custom remote-account workflow or configurable executable layer.

- [Native initializer](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-install-db)
- [Unix-socket authentication](https://mariadb.com/docs/server/reference/plugins/authentication-plugins/authentication-plugin-unix-socket)

Server startup is user-run. This repository has no test/check workflow.

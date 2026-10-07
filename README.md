# Local databases

My Make commands for starting supporting services locally and keeping their data in
this repository. Each service has one instance on the machine. Data is fixed under
`./data/<service>`; variables in the Makefiles only avoid repeating paths and options.

Use native binaries on PATH and their default ports. These are supporting services,
so development/preview server port-assignment rules do not apply.

## Commands

Initialize once, then choose foreground or background execution:

```sh
make mariadb-init
make mariadb-run
```

Or start explicitly in the background and stop it later:

```sh
make mariadb
make mariadb-stop
```

Connect with the local OS-user account through the repository's socket:

```sh
mariadb --socket="$PWD/data/mariadb/server.sock" --user="$(id -un)"
```

The same convention applies to `pg`, `redis`, `mailcatcher`, `typesense`, `garage`
and `rabbitmq`: `<service>-init`, `<service>-run`, `<service>` for background
execution, and `<service>-stop`. Bare `make` lists these commands.

Install service binaries yourself. No command installs software or registers a system
service. MariaDB replaces MySQL; existing `data/mysql/` remains untouched.

## Data

Stop a service before removing its `./data/<service>` directory yourself, then
initialize it again. There is no cleanup or automatic migration target.
Redis and Garage have small native config files in `config/`. MailCatcher's messages
are in memory and disappear when it stops.

Typesense uses the fixed development API key `local-development`.
Garage uses native key and bucket creation; see its [reference](docs/spec/garage.md).
RabbitMQ uses native default accounts and ports; its `epmd` helper is stopped by
`rabbitmq-stop` when idle. After a foreground RabbitMQ exits, use `epmd -kill` to
stop an idle helper; the native command refuses while other Erlang nodes remain.

There are no environment loaders, configurable executable paths, generic service
wrappers, or test/check workflows.

## References

- [Service commands](docs/spec/services.md)
- [MariaDB](docs/spec/mariadb.md)
- [Garage](docs/spec/garage.md)
- [Checked release baselines](docs/spec/modernization.md)

## License

WTFPL.

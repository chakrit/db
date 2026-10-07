# Native service release references

Status: implemented

The recipes use the minimal original Make convention: literal native commands,
DRY paths/options, fixed `./data/<service>` directories and native default ports.
There is no portable configuration framework, environment loader, executable override
system, export list or test/check workflow.

MariaDB replaces MySQL. Garage supplies S3-compatible object storage.
See [services.md](services.md) for the implemented command surface.

The following upstream interfaces were referenced on 2026-10-07. These versions are
documentation baselines, not package locks or claims of successful native startup:

- PostgreSQL 18.6: [official stable releases](https://www.postgresql.org/).
- MariaDB 13.0.2: installed Homebrew arm64 server/client version output.
- Redis 8.10.2: [official source releases](https://download.redis.io/releases/).
- MailCatcher 0.10.0: [upstream releases](https://github.com/sj26/mailcatcher/releases).
- Typesense 30.2: [upstream release](https://github.com/typesense/typesense/releases/tag/v30.2).
- Garage 2.4.1: [release builds](https://garagehq.deuxfleurs.fr/_releases.html).
- RabbitMQ 4.3.6: [release information](https://www.rabbitmq.com/release-information).

The user installs and upgrades native binaries. Follow upstream data-format upgrade
procedures; replacing a binary is not a data migration. Existing MySQL, PostgreSQL and
Redis data is preserved. RabbitMQ needs a supported Erlang version from the
[compatibility matrix](https://www.rabbitmq.com/docs/which-erlang).

These are local supporting services. Development/preview server port assignment,
8000–9000 restrictions and remote-binding rules do not apply.

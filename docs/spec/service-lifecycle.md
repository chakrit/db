# Required service lifecycle

Status: accepted

Every supported service has initialization, foreground execution, background execution
and stop commands. Use the original Make convention: `<service>-init`,
`<service>-run`, `<service>` for background execution, and `<service>-stop`.

There is only one instance of each service on the entire machine, always started through
this repository. Do not add checkout-specific instance isolation or automatic startup.

This is a personal tool for starting local databases and supporting services, keeping
their data in this repository for easy maintenance. Keep the setup minimal and follow
the original Make convention. Variables are for DRY paths and options, not configuration.

Hard-code the data root to `./data`, with `pg/`, `mariadb/`, `redis/`,
`mailcatcher/`, `typesense/`, `garage/` and `rabbitmq/` beneath it.
Use MariaDB instead of MySQL and Garage for S3-compatible object storage.
Existing MySQL data remains untouched. Tracked native config files live in `config/`.

Initialization prepares each service after the user removes its stopped data directory.
Foreground and background startup run the initialization prerequisite automatically to
prepare directories and required native initial state. Explicit initialization remains
available; repeated initialization retains existing data.
Do not discard populated data, introduce cleanup commands, or perform automatic upgrades.
Leave server startup and destructive removal to the user.

Supporting services use native default ports. Development/preview server port assignment,
8000–9000 restrictions and remote-binding rules do not apply to this repository.

Do not add configurable binaries, environment loaders, export lists, generic launchers,
custom account-bootstrap workflows or a portable configuration framework.

This project is exempt from tests. Do not write or retain test code, add automated
check/test targets, or run test/check workflows.

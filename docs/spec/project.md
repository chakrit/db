# Project structure and execution

Status: implemented

This is a personal GNU Make tool for starting local supporting services and keeping
their data in this repository for easy maintenance. It is not a configuration framework
or a tool intended to be dropped into other projects.

There is one instance of each service on the entire machine, always started here.
This repository does not work correctly on Linux. There, use the distribution's default
package installs and manage the services with systemctl: true Linux setups put things in
predictable folders that are easy to find and clean anyway.
Leave service startup and destructive directory removal to the user.

The root Makefile includes `make/*.mk`. Each service file contains direct native
commands and variables only for repeated paths and options. Binary names are literal,
ports are native defaults, and data is hard-coded under `./data/<service>`.
There are no environment loaders, configurable binary paths, export lists, generic
launch scripts or account-bootstrap workflows.

Each service has init, foreground run, background execution and stop tasks, following
the original naming convention: `<service>-init`, `<service>-run`, `<service>`,
and `<service>-stop`. Bare Make lists commands and starts nothing.

The active services are PostgreSQL, MariaDB, Redis, MailCatcher, Typesense, Garage and
RabbitMQ. MariaDB replaces MySQL and Garage supplies S3 storage. Existing MySQL data
is preserved. Existing PostgreSQL and Redis data is under `data/pg/` and `data/redis/`.

Tracked native configuration is in `config/`; generated service data and operational
files are ignored beneath `data/`. Initialization does not migrate existing data.
MailCatcher's messages are transient.

These are supporting services, not development or preview servers. The preview-server
port-assignment, 8000–9000 range and remote-binding rules do not apply here.

This project is exempt from tests. Do not retain test code, introduce automated
check/test targets, or run test/check workflows. Native server startup remains user-run.

Use the current branch and `gh` remote. Local commits are authorized; pushes require
explicit permission. Commands and docs work without ACE or any particular agent vendor.

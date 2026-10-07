# Required service lifecycle

Status: accepted

This is the intended behavior for modernization of this repository's local service
commands. [services.md](services.md) describes the existing implementation; that code
does not yet satisfy this contract consistently.

Every supported service must offer initialization, foreground execution, and background
execution. Every supported service must have an initialization task.

There is only one instance of each service on the entire machine, always started through
this repository. No checkout-specific instance isolation is required. Do not start
services automatically in the background.

Initialization must allow a fresh instance after the user removes the stopped service's
directory. Keep persistent service state under that repository-owned directory so the
user does not need to hunt down hidden state elsewhere to reset the instance.

The service data root is `data/`, with one directory per service: `pg/`, `mysql/`,
`redis/`, `mailcatcher/`, `typesense/`, `minio/`, and `rabbitmq/`. The directory scaffold
exists; existing recipes use it, and the existing PostgreSQL and Redis data was moved
into it. Mailcatcher, MinIO and RabbitMQ state routing still needs implementation.
Service initialization must recreate missing directories. Keep tracked configuration
outside disposable data directories.

Leave service startup and destructive directory removal to the user. Agents must not
execute destructive cleanup commands. Existing data must not be discarded by an
initialization task.

Structure environment variables sensibly. Every service Makefile must use a consistent
variable and task structure.

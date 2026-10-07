# Garage object storage

Status: implemented

Use Garage for this repository's S3-compatible object storage. Core S3 operations are
sufficient. Run one native, single-node instance on the machine through this repository.

This file records Garage's Make tasks and native service boundary for maintainers and
users operating the service. Native runtime checks remain unverified.
The [service lifecycle](service-lifecycle.md) applies to Garage. Reference baseline:
Garage **2.4.1**, released 2026-09-08; checked 2026-10-07.

## Host prerequisite

The host must supply a `garage` executable with SQLite support. Homebrew's `garage`
formula provides native Apple Silicon macOS bottles at version 2.4.1. Upstream's release
assets list Linux architectures; do not assume an upstream macOS download exists.
Installation is a separate user operation. Make tasks do not install dependencies or
enable a persistent system service.

- [Homebrew formula](https://formulae.brew.sh/formula/garage)
- [Official release builds](https://garagehq.deuxfleurs.fr/_releases.html)
- [2.4.1 release notes](https://git.deuxfleurs.fr/Deuxfleurs/garage/releases/tag/v2.4.1)

## Repository tasks and state

The targets are `garage-init`, `garage-run`, `garage-start`, `garage-stop`, and
`garage-status`. The service owner is `make/garage.mk`. Use the repository's shared
configuration precedence and process lifecycle conventions.

Keep the complete resettable instance under `data/garage/`:

```text
data/garage/
  garage.toml       generated instance configuration
  rpc-secret        owner-readable RPC authentication secret
  access-key        generated or locally supplied S3 key ID
  secret-key        generated or locally supplied S3 secret
  bucket            default bucket name
  meta/             node identity, keys, buckets, object index and SQLite database
  blocks/           object blocks
  garage.log        background stdout/stderr
  garage.pid        repository-managed background process identity
```

Keep any tracked configuration template under `config/`, outside the disposable state.
Resolve filesystem paths absolutely. SQLite creates `meta/db.sqlite` and its journal
files within the metadata directory. Do not move its journal files separately.

`garage-init` prepares missing directories and instance configuration without starting
the server. First server startup creates native metadata and the single-node layout,
then creates the default key and bucket. Repeated initialization preserves existing
state and credentials. It must reject inconsistent partial state instead of replacing
metadata or silently generating a second identity.

The user resets Garage by stopping it, removing its complete service directory, then
initializing and starting it again. No target deletes existing objects or directories.

## Configuration boundary

Use `GARAGE_` names for repository settings and pass only the vendor environment values
needed by the invoked command. Executable, data/config paths, listener settings,
credentials, then derived arguments follow the shared ordering.

The minimal single-node configuration uses these Garage 2.4.1 public fields:

```toml
metadata_dir = "<absolute service directory>/meta"
data_dir = "<absolute service directory>/blocks"
db_engine = "sqlite"
replication_factor = 1
rpc_bind_addr = "127.0.0.1:<assigned RPC port>"
rpc_public_addr = "127.0.0.1:<assigned RPC port>"
rpc_secret_file = "<absolute service directory>/rpc-secret"

[s3_api]
s3_region = "garage"
api_bind_addr = "0.0.0.0:<assigned S3 port>"
```

This is a field reference, not a ready-to-run file: substitute validated absolute paths
and assigned ports. Obtain ports from the control agent before committing defaults.
`rpc_bind_addr` accepts CLI connections; `rpc_public_addr` tells the local CLI where to
connect. Internal RPC binds to loopback; the remotely used S3 listener binds to
`0.0.0.0`. Both ports require explicit settings and must differ.

| Repository variable  | Default or purpose                              |
| -------------------- | ----------------------------------------------- |
| `GARAGE_SERVER_BIN`  | `garage` executable                             |
| `GARAGE_DATA_DIR`    | `$(DB_DATA_ROOT)/garage`                        |
| `GARAGE_CONFIG_FILE` | `$(GARAGE_DATA_DIR)/garage.toml`                |
| `GARAGE_LOG_FILE`    | `$(GARAGE_DATA_DIR)/garage.log`                 |
| `GARAGE_PID_FILE`    | `$(GARAGE_DATA_DIR)/garage.pid`                 |
| `GARAGE_HOST`        | `0.0.0.0` S3 bind address                       |
| `GARAGE_PORT`        | Assigned S3 port; no default                    |
| `GARAGE_RPC_PORT`    | Assigned RPC port; no default                   |
| `GARAGE_ACCESS_KEY`  | Optional GK + 32 hex; generated when absent     |
| `GARAGE_SECRET_KEY`  | Optional 64 hex; generated when absent          |
| `GARAGE_BUCKET`      | `local-bucket`                                  |

Initialization records listener settings and credentials in the instance files. Repeated
initialization does not change an existing configuration or rotate credentials. Inspect
the generated configuration when changing an initialized instance's listener settings.

The RPC secret file contains a 32-byte hexadecimal secret and is owner-readable only.
Store instance-generated secrets beneath `data/garage/`; personal credential overrides
belong in ignored local configuration. Do not commit real credentials or bypass Garage's
secret-file permission checks. Keep generated configuration owner-readable only if it
contains credentials.

The S3 API uses HTTP. TLS requires a reverse proxy, which is outside this local service
integration. Path-style S3 addressing works without `root_domain`. The optional
`[s3_web]` website and `[admin]` HTTP listeners are unnecessary for basic S3 and CLI
readiness; leaving them unconfigured avoids additional listeners.

[Versioned configuration reference](https://github.com/deuxfleurs-org/garage/blob/v2.4.1/doc/book/reference-manual/configuration.md)

## Public CLI and credentials

The repository launcher invokes the server with the same configuration in both modes:

Make exports launcher settings to its subprocesses, not to the user's shell. For the
direct CLI examples below, set these shell variables from the default repository paths;
adjust them if the configured data root differs:

```sh
GARAGE_CONFIG_FILE="$PWD/data/garage/garage.toml"
GARAGE_DEFAULT_ACCESS_KEY="$(cat "$PWD/data/garage/access-key")"
GARAGE_DEFAULT_SECRET_KEY="$(cat "$PWD/data/garage/secret-key")"
GARAGE_DEFAULT_BUCKET="$(cat "$PWD/data/garage/bucket")"
export GARAGE_DEFAULT_ACCESS_KEY GARAGE_DEFAULT_SECRET_KEY GARAGE_DEFAULT_BUCKET
```

```sh
garage -c "$GARAGE_CONFIG_FILE" server --single-node --default-bucket
```

The launcher reads its instance credential files and provides these vendor variables
for default credential and bucket bootstrap:

| Variable                    | Meaning                                       |
| --------------------------- | --------------------------------------------- |
| `GARAGE_DEFAULT_ACCESS_KEY` | S3 key ID; documented example is GK + 32 hex  |
| `GARAGE_DEFAULT_SECRET_KEY` | Associated S3 secret; example is 64 hex       |
| `GARAGE_DEFAULT_BUCKET`     | Valid S3 bucket name                          |
| `GARAGE_CONFIG_FILE`        | Config path; equivalent to CLI `-c`           |

The default key and bucket flags are booleans; do not append key IDs or bucket names to
them. `--default-bucket` implies `--default-access-key`. Both require `--single-node`,
which requires `replication_factor = 1` and refuses an existing multi-node cluster.
Automatic bootstrap is supported since v2.3.0.

The bootstrap key and secret are readable from `data/garage/access-key` and
`data/garage/secret-key`. Treat their contents as credentials; do not commit them.
Use the same credentials across restarts. Startup does not constitute credential
rotation. Additional buckets and grants use the public CLI:

```sh
garage -c "$GARAGE_CONFIG_FILE" bucket create app-bucket
garage -c "$GARAGE_CONFIG_FILE" bucket allow --read --write --owner \
  app-bucket --key "$GARAGE_DEFAULT_ACCESS_KEY"
```

`RUST_LOG=garage=info` is the normal logging level; `garage=debug` helps investigate S3
requests. Logs go to stderr by default; background execution captures stdout and stderr
under the service directory.

- [Quick start](https://garagehq.deuxfleurs.fr/documentation/quick-start/)
- [2.4.1 CLI surface](https://github.com/deuxfleurs-org/garage/blob/v2.4.1/src/garage/cli/structs.rs)

## Readiness and stopping

Use the public health command for the readiness outcome:

```sh
garage -c "$GARAGE_CONFIG_FILE" health --quiet
```

Garage 2.4.1 supports `health`; it exits nonzero when the cluster is unavailable.
`garage status` reports node information and is useful diagnostically. Do not interpret
successful process creation or an open TCP socket as storage readiness.

The background launcher returns only after bounded readiness succeeds. A failed start
reports its log location and does not claim success. Garage has no native daemon flag,
PID-file option or shutdown subcommand in this baseline. Use the repository's process
launcher, preserving the same server command for foreground and background operation.

Foreground Ctrl-C sends SIGINT. Background stop sends SIGTERM to the recorded process
and waits for graceful exit. Both signals trigger Garage's shutdown sequence; SIGHUP
does not reload configuration. Stop preserves configuration, metadata and object blocks.

An optional admin HTTP listener exposes `/metrics`. It is a metrics endpoint, not a
substitute for `health`. This integration does not require the admin listener.

- [2.4.0 health command introduction](https://git.deuxfleurs.fr/Deuxfleurs/garage/releases/tag/v2.4.0)
- [2.4.1 signal behavior](https://github.com/deuxfleurs-org/garage/blob/v2.4.1/src/garage/server.rs)
- [Monitoring endpoint](https://garagehq.deuxfleurs.fr/documentation/cookbook/monitoring/)

## Compatibility and version boundaries

The required surface is core S3: bucket/object operations, multipart uploads, SigV4,
presigned URLs and path-style addressing. Garage does not implement bucket versioning or
S3 ACL/bucket-policy administration. Its own per-key/per-bucket permissions apply.
Missing S3 endpoints return 501. Lifecycle actions are limited to object expiration and
incomplete multipart-upload cleanup.

SQLite is the single-node metadata backend. Upstream describes it as slower
than LMDB but without LMDB's documented unclean-shutdown corruption and architecture
portability restrictions. Single-node operation supplies no redundant copy. No native
macOS throughput or crash-recovery measurement has been performed for this repository.

Do not copy new settings from the live website into a pinned baseline without checking
the matching tag. In particular, `advertise_endpoint` was merged after the 2.4.1 release
and is not a 2.4.1 configuration feature.

- [S3 compatibility](https://garagehq.deuxfleurs.fr/documentation/reference-manual/s3-compatibility/)
- [Versioned metadata engine reference](https://github.com/deuxfleurs-org/garage/blob/v2.4.1/doc/book/reference-manual/configuration.md)

## User-run verification

With an installed compatible binary, assigned ports and local credentials:

1. Run `make garage-init`, then `make garage-run`; confirm S3 access and interrupt with
   Ctrl-C.
2. Run `make garage-start`, then `make garage-status`; upload/download an object using
   the configured endpoint, credentials, region `garage` and path-style addressing.
3. Exercise multipart upload and a presigned download using the application's S3 client.
4. Run `make garage-stop`, start again, and confirm the object and credentials persist.
5. Stop Garage before the user removes its directory; run init and start again and
   confirm a fresh default bucket.

These runtime checks remain unverified until the user runs the implemented tasks.

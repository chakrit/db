# Garage S3 storage

Status: implemented

Use Garage for S3-compatible object storage. Core S3 is sufficient for this repository.
The native interface reference is Garage 2.4.1, released 2026-09-08.
[make/garage.mk](../../make/garage.mk) calls Garage directly; it does not configure
executable paths or load environment files.

## Local commands

```sh
make garage-init
make garage-run
```

For background execution instead:

```sh
make garage
make garage-stop
```

Initialization creates `./data/garage/meta`, `./data/garage/blocks` and a private
RPC secret. Existing secrets are retained. First startup creates native metadata and
the single-node layout. Background output and PID live in that same service directory.

[config/garage.toml](../../config/garage.toml) is a small static native configuration:
SQLite metadata, one replica, S3 at `127.0.0.1:3900`, and RPC at `127.0.0.1:3901`.
Data paths are fixed under `./data/garage`. No admin HTTP listener is added.

## Native credentials and buckets

After starting the server, use its native CLI to create a key and bucket:

```sh
garage -c ./config/garage.toml key create local
garage -c ./config/garage.toml bucket create local-bucket
garage -c ./config/garage.toml bucket allow --read --write --owner local-bucket --key local
```

The key-creation output supplies the access and secret keys for the application's S3
client. Use endpoint `http://127.0.0.1:3900`, region `garage` and path-style addressing.
No custom account-bootstrap layer or credential override system is provided.

Native health is `garage -c ./config/garage.toml health --quiet`.
Foreground Ctrl-C and background SIGTERM trigger graceful native shutdown.
Stop preserves metadata and object blocks.

## Compatibility and references

Garage supports core object operations, multipart uploads, SigV4 and presigned URLs.
It does not provide S3 bucket policies, object versioning or object locking.
SQLite avoids the documented LMDB unclean-shutdown/portability restrictions, with a
performance tradeoff. Single-node storage has no redundant copy.

The user installs the native `garage` binary; Homebrew provides Apple Silicon builds.
Do not copy newer website settings into 2.4.1 without checking its versioned reference.

- [Quick start](https://garagehq.deuxfleurs.fr/documentation/quick-start/)
- [Release builds](https://garagehq.deuxfleurs.fr/_releases.html)
- [Native configuration](https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/)
- [S3 compatibility](https://garagehq.deuxfleurs.fr/documentation/reference-manual/s3-compatibility/)
- [Native Homebrew package](https://formulae.brew.sh/formula/garage)

Server startup is user-run. This repository has no test/check workflow.

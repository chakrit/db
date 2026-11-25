# db

This repository wraps host-installed local services with GNU Make. The root Makefile
includes make/*.mk; each file owns one service's direct native commands. This is a
personal tool for starting local supporting services and keeping their data in this
checkout, not a reusable configuration framework.

## Control

Applies only inside a control setup: this folder is `~/work/chakrit/db` and the org
control's folder `~/work/chakrit/control` exists on this machine. If either is not
true, ignore this section; it belongs to another person's agent setup.

Inside the setup, you are `ga42:chakrit:db`, a project control under
`ga42:chakrit:control`. Your standing grant (session start, rule entries, rulings,
ports, processes) lives in engram project `ga42-chakrit-db`, topic key
`control/grant`. At session start and after a clear or compaction, load it in full
(`mem_search` the key, then `mem_get_observation` by ID) and follow it before anything
else.

## Layout and commands

- make/pg.mk, mariadb.mk, redis.mk, mailcatcher.mk, typesense.mk, garage.mk and
  rabbitmq.mk: <service>-init, <service>-run, <service> (background), <service>-stop.
- data/<service>/: persistent data and operational files.
- config/: the native Redis and Garage configuration files.

Hard-code data under ./data. Make variables exist only to keep repeated paths and
command options DRY and consistent. Use literal binary names and native default ports;
do not add configurable binaries, environment loaders, export lists, generic launchers,
custom account-bootstrap workflows or a portable configuration framework.

These are supporting services, not development or preview servers. The preview-server
port-assignment, 8000–9000 range and remote-binding rules do not apply here.

Run make targets only when the user authorizes the service operation. Leave server
startup to the user. Do not run destructive cleanup commands from README.md.
There is only one instance of each service on the entire machine, always started through
this repository, except on Linux. No checkout-specific instance isolation is required.
Background startup is explicit; this repository registers no system service. MariaDB
replaces MySQL; Garage supplies S3.

This repository does not work correctly on Linux. There, use the distribution's default
package installs and manage the services with systemctl: true Linux setups put things in
predictable folders that are easy to find and clean anyway.

## Conventions and verification

This project is exempt from test requirements. Do not write or retain test code, add
automated check/test targets (including `make check`), or run test/check workflows.
Leave service startup to the user.

Keep service recipes in their existing make/*.mk owner and use tabs for recipes.
Use the gh remote and current branch by default. Preserve tight resource budgets and
never increase timeouts without the user's explicit authorization. Do not introduce
TypeScript, Helm, GitHub Actions, Firebase, or awk.

Review changed recipes and configuration without starting services. For ACE changes,
verify ace skills and ace config, then inspect the complete Git diff before committing.
For documentation changes, verify routing, links, and the spec index.

## Durable artifacts

`docs/` holds this project's durable record.

**`docs/spec/` is authoritative — read the relevant spec before working, and comply.**
It owes no justification: a rule that departs from mainstream practice, from what you
would have picked, or from what you expected is not grounds to escalate, annotate, or
re-open it. If a spec is wrong, raise it with the user and amend the spec.

**Everything settled is a `docs/spec/` amendment** — an instruction you were given, an
approach that was agreed, a library that was picked, a convention or preference that
was fixed. Write it there as it was given: the rule, at the length it was given, with
no reason supplied and no note of what it was chosen over. A one-sentence rule — "use
RESTful routes" — is a complete entry. There is no decisions log.

File new material by the gate, first match wins: our own design or surface → `spec/`.
Nothing defaults to `scratch/`.

**Before writing under `docs/`, read `docs/README.md`, then the destination folder's
`README.md`.** The root file defines the routing gate. The folder file defines its
filing test, filename format, and lifecycle rules. Both are binding.

**`docs/spec/README.md` indexes every spec file — keep it current.** Read the index
before adding a spec file, so you amend the existing doc on a subject instead of
writing a second one. Adding, renaming, or retiring a file updates its row in the same
change.

## ACE configuration

ace.toml holds the shared school and skill selection; ignored ace.local.toml holds
personal overrides. Shared skills: ace, ace-init, ace-save, ace-docs, code, safety-audit.
User-level inclusions may add personal skills; inspect ace skills for the resolved set.
Load code for every coding task.

ACE is optional tooling. Repository instructions, docs, Make commands, and Git checks
remain usable by humans and agents without ACE. Do not edit school files through
generated skill links as part of repository work.

## Git checkpoints

Commit coherent, completed slices autonomously after completing the checks required for
that work. Do not ask for permission to make a local commit. A local commit does not
authorize pushing, publishing, merging, releasing, deploying, or any other change to
shared or external state; each requires separate user authorization.

# db

This repository wraps host-installed local services with GNU Make. The root Makefile
includes make/*.mk; each file owns one service's commands. It contains no application
build or automated test suite.

## Layout and commands

- make/pg.mk: pg-init, pg-run, pg, pg-stop; data and logs under pg/.
- make/mysql.mk: mysql-init, mysql-run, mysql, mysql-stop, mysql-logs; data under mysql/.
- make/redis.mk: redis-run, redis, redis-stop; tracked config redis/redis.conf.
- make/mailcatcher.mk: mc-run, mc, mailcatcher, mc-stop.
- make/typesense.mk: ts and typesense run in the foreground; data under ts/.
- scripts/mysql-logs.sql: the SQL used by mysql-logs to enable general-query logging.
- .ruby-version: Ruby 3.3.6.

Run make targets only when the user authorizes the service operation. Leave server
startup to the user. Do not run destructive cleanup commands from README.md.
There is no redis-init target despite the README example. MySQL and Redis stop targets
use default connection settings; check the intended instance before using them.

## Conventions and verification

Keep service recipes in their existing make/*.mk owner and use tabs for recipes.
Use the gh remote and current branch by default. Preserve tight resource budgets and
never increase timeouts without the user's explicit authorization. Do not introduce
TypeScript, Helm, GitHub Actions, Firebase, or awk.

Review changed recipes and configuration without starting services. For ACE changes,
verify ace skills and ace config, then inspect the complete Git diff before committing.
For documentation changes, verify routing, links, and the spec index.

## ACE configuration

ace.toml holds the shared school and skill selection; ignored ace.local.toml holds
personal overrides. Shared skills: ace, ace-init, ace-save, ace-docs, architect, code,
safety-audit. User-level inclusions may add personal skills; inspect ace skills for the
resolved set. Load architect and code for every coding task.

ACE is optional tooling. Repository instructions, docs, Make commands, and Git checks
remain usable by humans and agents without ACE. Do not edit school files through
generated skill links as part of repository work.

## Git checkpoints

Commit coherent, completed slices autonomously after completing the checks required for
that work. Do not ask for permission to make a local commit. A local commit does not
authorize pushing, publishing, merging, releasing, deploying, or any other change to
shared or external state; each requires separate user authorization.

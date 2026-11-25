PG_DIR         := ./data/pg
PG_OPTS        := -D $(PG_DIR)
PG_LOG_OPTS    := -l $(PG_DIR)/postgres.log
# Upstream's socket directory; Debian's build moves it to /var/run/postgresql.
PG_SERVER_OPTS := -k /tmp

# Debian keeps the server binaries off PATH, under /usr/lib/postgresql/<version>/bin.
export PATH := $(shell pg_config --bindir):$(PATH)

.PHONY: pg-init pg-run pg pg-stop

pg-init:
	mkdir -p $(PG_DIR)
	@if [ -s $(PG_DIR)/PG_VERSION ] && [ -f $(PG_DIR)/global/pg_control ]; then \
		printf '%s\n' 'PostgreSQL is already initialized.'; \
	else \
		initdb $(PG_OPTS); \
	fi

pg-run: | pg-init
	postgres $(PG_OPTS) $(PG_SERVER_OPTS)

pg: | pg-init
	pg_ctl start $(PG_OPTS) $(PG_LOG_OPTS) -o '$(PG_SERVER_OPTS)'

pg-stop:
	pg_ctl stop $(PG_OPTS)

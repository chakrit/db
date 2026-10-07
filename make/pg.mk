PG_DIR      := ./data/pg
PG_OPTS     := -D $(PG_DIR)
PG_LOG_OPTS := -l $(PG_DIR)/postgres.log

.PHONY: pg-init pg-run pg pg-stop

pg-init:
	mkdir -p $(PG_DIR)
	@if [ -s $(PG_DIR)/PG_VERSION ] && [ -f $(PG_DIR)/global/pg_control ]; then \
		printf '%s\n' 'PostgreSQL is already initialized.'; \
	else \
		initdb $(PG_OPTS); \
	fi

pg-run:
	postgres $(PG_OPTS)

pg:
	pg_ctl start $(PG_OPTS) $(PG_LOG_OPTS)

pg-stop:
	pg_ctl stop $(PG_OPTS)

MARIADB_DIR       := $(abspath ./data/mariadb)
MARIADB_SOCKET    := $(MARIADB_DIR)/server.sock
MARIADB_LOG       := $(MARIADB_DIR)/server.log
MARIADB_QUERY_LOG := $(MARIADB_DIR)/queries.log
MARIADB_OPTS      := --no-defaults --datadir="$(MARIADB_DIR)/db" \
                    --socket="$(MARIADB_SOCKET)" --pid-file="$(MARIADB_DIR)/server.pid" \
                    --tmpdir="$(MARIADB_DIR)/tmp" --log-error="$(MARIADB_LOG)" \
                    --general-log-file="$(MARIADB_QUERY_LOG)"
MARIADB_CLIENT_OPTS := --no-defaults --socket="$(MARIADB_SOCKET)" --user="$$(id -un)"

.PHONY: mariadb-init mariadb-run mariadb mariadb-stop mariadb-logs

mariadb-init:
	mkdir -p "$(MARIADB_DIR)/db" "$(MARIADB_DIR)/tmp"
	@if [ -d "$(MARIADB_DIR)/db/mysql" ]; then \
		printf '%s\n' 'MariaDB is already initialized.'; \
	else \
		mariadb-install-db --no-defaults --datadir="$(MARIADB_DIR)/db" \
			--auth-root-authentication-method=socket --auth-root-socket-user="$$(id -un)" \
			--skip-test-db; \
	fi

mariadb-run: | mariadb-init
	mariadbd $(MARIADB_OPTS)

mariadb: | mariadb-init
	@nohup mariadbd $(MARIADB_OPTS) >> "$(MARIADB_LOG)" 2>&1 < /dev/null & \
		printf 'MariaDB PID: %s; log: %s\n' "$$!" "$(MARIADB_LOG)"

mariadb-stop:
	mariadb-admin $(MARIADB_CLIENT_OPTS) shutdown

mariadb-logs:
	mariadb $(MARIADB_CLIENT_OPTS) --execute="SET GLOBAL log_output = 'FILE'; SET GLOBAL general_log = 1;"
	tail -f "$(MARIADB_QUERY_LOG)"

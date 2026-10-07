MARIADB_SERVER_BIN ?= mariadbd
MARIADB_INIT_BIN   ?= mariadb-install-db
MARIADB_CLIENT_BIN ?= mariadb
MARIADB_ADMIN_BIN  ?= mariadb-admin

MARIADB_DATA_DIR       ?= $(DB_DATA_ROOT)/mariadb
MARIADB_SOCKET         ?= $(MARIADB_DATA_DIR)/server.sock
MARIADB_PID_FILE       ?= $(MARIADB_DATA_DIR)/server.pid
MARIADB_LOG_FILE       ?= $(MARIADB_DATA_DIR)/server.log
MARIADB_QUERY_LOG_FILE ?= $(MARIADB_DATA_DIR)/queries.log

MARIADB_HOST ?= 0.0.0.0
MARIADB_PORT ?=

MARIADB_USER            ?=
MARIADB_REMOTE_USER     ?= dev
MARIADB_REMOTE_PASSWORD ?=

mariadb-%: export MARIADB_SERVER_BIN := $(MARIADB_SERVER_BIN)
mariadb-%: export MARIADB_INIT_BIN := $(MARIADB_INIT_BIN)
mariadb-%: export MARIADB_CLIENT_BIN := $(MARIADB_CLIENT_BIN)
mariadb-%: export MARIADB_ADMIN_BIN := $(MARIADB_ADMIN_BIN)
mariadb-%: export MARIADB_DATA_DIR := $(MARIADB_DATA_DIR)
mariadb-%: export MARIADB_SOCKET := $(MARIADB_SOCKET)
mariadb-%: export MARIADB_PID_FILE := $(MARIADB_PID_FILE)
mariadb-%: export MARIADB_LOG_FILE := $(MARIADB_LOG_FILE)
mariadb-%: export MARIADB_QUERY_LOG_FILE := $(MARIADB_QUERY_LOG_FILE)
mariadb-%: export MARIADB_HOST := $(MARIADB_HOST)
mariadb-%: export MARIADB_PORT := $(MARIADB_PORT)
mariadb-%: export MARIADB_USER := $(MARIADB_USER)
mariadb-%: export MARIADB_REMOTE_USER := $(MARIADB_REMOTE_USER)
mariadb-%: export MARIADB_REMOTE_PASSWORD := $(MARIADB_REMOTE_PASSWORD)

.PHONY: mariadb-init mariadb-run mariadb-start mariadb-stop mariadb-status mariadb-bootstrap mariadb-shell mariadb-logs

mariadb-init:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" init

mariadb-run:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" run

mariadb-start:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" start

mariadb-stop:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" stop

mariadb-status:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" status

mariadb-bootstrap:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" bootstrap

mariadb-shell:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" shell

mariadb-logs:
	@sh "$(DB_ROOT)/scripts/mariadb.sh" logs

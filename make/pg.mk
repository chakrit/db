PG_SERVER_BIN  ?= postgres
PG_CLIENT_BIN  ?= pg_isready
PG_CONTROL_BIN ?= pg_ctl
PG_INIT_BIN    ?= initdb

PG_DATA_DIR   ?= $(DB_DATA_ROOT)/pg
PG_LOG_FILE   ?= $(PG_DATA_DIR)/postgres.log
PG_SOCKET_DIR ?= $(PG_DATA_DIR)/socket

PG_HOST ?= 0.0.0.0
PG_PORT ?=

PG_USER     ?= postgres
PG_PASSWORD ?=

pg-%: export PG_SERVER_BIN := $(PG_SERVER_BIN)
pg-%: export PG_CLIENT_BIN := $(PG_CLIENT_BIN)
pg-%: export PG_CONTROL_BIN := $(PG_CONTROL_BIN)
pg-%: export PG_INIT_BIN := $(PG_INIT_BIN)
pg-%: export PG_DATA_DIR := $(PG_DATA_DIR)
pg-%: export PG_LOG_FILE := $(PG_LOG_FILE)
pg-%: export PG_SOCKET_DIR := $(PG_SOCKET_DIR)
pg-%: export PG_HOST := $(PG_HOST)
pg-%: export PG_PORT := $(PG_PORT)
pg-%: export PG_USER := $(PG_USER)
pg-%: export PG_PASSWORD := $(PG_PASSWORD)

.PHONY: pg-init pg-run pg-start pg-stop pg-status

pg-init:
	@sh "$(DB_ROOT)/scripts/pg.sh" init

pg-run:
	@sh "$(DB_ROOT)/scripts/pg.sh" run

pg-start:
	@sh "$(DB_ROOT)/scripts/pg.sh" start

pg-stop:
	@sh "$(DB_ROOT)/scripts/pg.sh" stop

pg-status:
	@sh "$(DB_ROOT)/scripts/pg.sh" status

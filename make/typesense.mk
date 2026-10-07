TYPESENSE_SERVER_BIN ?= typesense-server
TYPESENSE_CLIENT_BIN ?= curl

TYPESENSE_DATA_DIR ?= $(DB_DATA_ROOT)/typesense
TYPESENSE_LOG_DIR ?= $(TYPESENSE_DATA_DIR)/logs
TYPESENSE_LOG_FILE ?= $(TYPESENSE_DATA_DIR)/typesense.log
TYPESENSE_PID_FILE ?= $(TYPESENSE_DATA_DIR)/typesense.pid

TYPESENSE_HOST ?= 0.0.0.0
TYPESENSE_PORT ?=
TYPESENSE_PEERING_PORT ?=

TYPESENSE_API_KEY ?=

typesense-%: export TYPESENSE_SERVER_BIN := $(TYPESENSE_SERVER_BIN)
typesense-%: export TYPESENSE_CLIENT_BIN := $(TYPESENSE_CLIENT_BIN)
typesense-%: export TYPESENSE_DATA_DIR := $(TYPESENSE_DATA_DIR)
typesense-%: export TYPESENSE_LOG_DIR := $(TYPESENSE_LOG_DIR)
typesense-%: export TYPESENSE_LOG_FILE := $(TYPESENSE_LOG_FILE)
typesense-%: export TYPESENSE_PID_FILE := $(TYPESENSE_PID_FILE)
typesense-%: export TYPESENSE_HOST := $(TYPESENSE_HOST)
typesense-%: export TYPESENSE_PORT := $(TYPESENSE_PORT)
typesense-%: export TYPESENSE_PEERING_PORT := $(TYPESENSE_PEERING_PORT)
typesense-%: export TYPESENSE_API_KEY := $(TYPESENSE_API_KEY)

.PHONY: typesense-init typesense-run typesense-start typesense-stop typesense-status

typesense-init:
	@sh "$(DB_ROOT)/scripts/typesense.sh" init

typesense-run:
	@sh "$(DB_ROOT)/scripts/typesense.sh" run

typesense-start:
	@sh "$(DB_ROOT)/scripts/typesense.sh" start

typesense-stop:
	@sh "$(DB_ROOT)/scripts/typesense.sh" stop

typesense-status:
	@sh "$(DB_ROOT)/scripts/typesense.sh" status

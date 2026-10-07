GARAGE_SERVER_BIN ?= garage

GARAGE_DATA_DIR ?= $(DB_DATA_ROOT)/garage
GARAGE_CONFIG_FILE ?= $(GARAGE_DATA_DIR)/garage.toml
GARAGE_LOG_FILE ?= $(GARAGE_DATA_DIR)/garage.log
GARAGE_PID_FILE ?= $(GARAGE_DATA_DIR)/garage.pid

GARAGE_HOST ?= 0.0.0.0
GARAGE_PORT ?=
GARAGE_RPC_PORT ?=

GARAGE_ACCESS_KEY ?=
GARAGE_SECRET_KEY ?=
GARAGE_BUCKET ?= local-bucket

garage-%: export GARAGE_SERVER_BIN := $(GARAGE_SERVER_BIN)
garage-%: export GARAGE_DATA_DIR := $(GARAGE_DATA_DIR)
garage-%: export GARAGE_CONFIG_FILE := $(GARAGE_CONFIG_FILE)
garage-%: export GARAGE_LOG_FILE := $(GARAGE_LOG_FILE)
garage-%: export GARAGE_PID_FILE := $(GARAGE_PID_FILE)
garage-%: export GARAGE_HOST := $(GARAGE_HOST)
garage-%: export GARAGE_PORT := $(GARAGE_PORT)
garage-%: export GARAGE_RPC_PORT := $(GARAGE_RPC_PORT)
garage-%: export GARAGE_ACCESS_KEY := $(GARAGE_ACCESS_KEY)
garage-%: export GARAGE_SECRET_KEY := $(GARAGE_SECRET_KEY)
garage-%: export GARAGE_BUCKET := $(GARAGE_BUCKET)

.PHONY: garage-init garage-run garage-start garage-stop garage-status

garage-init:
	@sh "$(DB_ROOT)/scripts/garage.sh" init

garage-run:
	@sh "$(DB_ROOT)/scripts/garage.sh" run

garage-start:
	@sh "$(DB_ROOT)/scripts/garage.sh" start

garage-stop:
	@sh "$(DB_ROOT)/scripts/garage.sh" stop

garage-status:
	@sh "$(DB_ROOT)/scripts/garage.sh" status

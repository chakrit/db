RABBITMQ_SERVER_BIN  ?= rabbitmq-server
RABBITMQ_CONTROL_BIN ?= rabbitmqctl
RABBITMQ_CLIENT_BIN  ?= rabbitmq-diagnostics
RABBITMQ_EPMD_BIN    ?= epmd

RABBITMQ_DATA_DIR    ?= $(DB_DATA_ROOT)/rabbitmq
RABBITMQ_CONFIG_FILE ?= $(DB_CONFIG_ROOT)/rabbitmq.conf
RABBITMQ_COOKIE_FILE ?= $(RABBITMQ_DATA_DIR)/.erlang.cookie
RABBITMQ_PID_FILE    ?= $(RABBITMQ_DATA_DIR)/rabbitmq.pid
RABBITMQ_LOG_FILE    ?= $(RABBITMQ_DATA_DIR)/log/rabbitmq.log

RABBITMQ_HOST      ?= 0.0.0.0
RABBITMQ_PORT      ?=
RABBITMQ_DIST_PORT ?=
RABBITMQ_NODENAME  ?= rabbit@localhost

RABBITMQ_USER     ?= dev
RABBITMQ_PASSWORD ?=

rabbitmq-%: export RABBITMQ_SERVER_BIN := $(RABBITMQ_SERVER_BIN)
rabbitmq-%: export RABBITMQ_CONTROL_BIN := $(RABBITMQ_CONTROL_BIN)
rabbitmq-%: export RABBITMQ_CLIENT_BIN := $(RABBITMQ_CLIENT_BIN)
rabbitmq-%: export RABBITMQ_EPMD_BIN := $(RABBITMQ_EPMD_BIN)
rabbitmq-%: export RABBITMQ_DATA_DIR := $(RABBITMQ_DATA_DIR)
rabbitmq-%: export RABBITMQ_CONFIG_FILE := $(RABBITMQ_CONFIG_FILE)
rabbitmq-%: export RABBITMQ_COOKIE_FILE := $(RABBITMQ_COOKIE_FILE)
rabbitmq-%: export RABBITMQ_PID_FILE := $(RABBITMQ_PID_FILE)
rabbitmq-%: export RABBITMQ_LOG_FILE := $(RABBITMQ_LOG_FILE)
rabbitmq-%: export RABBITMQ_HOST := $(RABBITMQ_HOST)
rabbitmq-%: export RABBITMQ_PORT := $(RABBITMQ_PORT)
rabbitmq-%: export RABBITMQ_DIST_PORT := $(RABBITMQ_DIST_PORT)
rabbitmq-%: export RABBITMQ_NODENAME := $(RABBITMQ_NODENAME)
rabbitmq-%: export RABBITMQ_USER := $(RABBITMQ_USER)
rabbitmq-%: export RABBITMQ_PASSWORD := $(RABBITMQ_PASSWORD)

.PHONY: rabbitmq-init rabbitmq-run rabbitmq-start rabbitmq-stop rabbitmq-status

rabbitmq-init:
	@sh "$(DB_ROOT)/scripts/rabbitmq.sh" init

rabbitmq-run:
	@sh "$(DB_ROOT)/scripts/rabbitmq.sh" run

rabbitmq-start:
	@sh "$(DB_ROOT)/scripts/rabbitmq.sh" start

rabbitmq-stop:
	@sh "$(DB_ROOT)/scripts/rabbitmq.sh" stop

rabbitmq-status:
	@sh "$(DB_ROOT)/scripts/rabbitmq.sh" status

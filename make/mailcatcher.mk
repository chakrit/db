MAILCATCHER_SERVER_BIN ?= mailcatcher
MAILCATCHER_CLIENT_BIN ?= curl

MAILCATCHER_DATA_DIR ?= $(DB_DATA_ROOT)/mailcatcher
MAILCATCHER_LOG_FILE ?= $(MAILCATCHER_DATA_DIR)/server.log
MAILCATCHER_PID_FILE ?= $(MAILCATCHER_DATA_DIR)/server.pid

MAILCATCHER_HOST      ?= 0.0.0.0
MAILCATCHER_SMTP_PORT ?=
MAILCATCHER_HTTP_PORT ?=

mailcatcher-%: export MAILCATCHER_SERVER_BIN := $(MAILCATCHER_SERVER_BIN)
mailcatcher-%: export MAILCATCHER_CLIENT_BIN := $(MAILCATCHER_CLIENT_BIN)
mailcatcher-%: export MAILCATCHER_DATA_DIR := $(MAILCATCHER_DATA_DIR)
mailcatcher-%: export MAILCATCHER_LOG_FILE := $(MAILCATCHER_LOG_FILE)
mailcatcher-%: export MAILCATCHER_PID_FILE := $(MAILCATCHER_PID_FILE)
mailcatcher-%: export MAILCATCHER_HOST := $(MAILCATCHER_HOST)
mailcatcher-%: export MAILCATCHER_SMTP_PORT := $(MAILCATCHER_SMTP_PORT)
mailcatcher-%: export MAILCATCHER_HTTP_PORT := $(MAILCATCHER_HTTP_PORT)

.PHONY: mailcatcher-init mailcatcher-run mailcatcher-start mailcatcher-stop mailcatcher-status

mailcatcher-init:
	@sh "$(DB_ROOT)/scripts/mailcatcher.sh" init

mailcatcher-run:
	@sh "$(DB_ROOT)/scripts/mailcatcher.sh" run

mailcatcher-start:
	@sh "$(DB_ROOT)/scripts/mailcatcher.sh" start

mailcatcher-stop:
	@sh "$(DB_ROOT)/scripts/mailcatcher.sh" stop

mailcatcher-status:
	@sh "$(DB_ROOT)/scripts/mailcatcher.sh" status

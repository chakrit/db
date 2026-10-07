REDIS_SERVER_BIN ?= redis-server
REDIS_CLIENT_BIN ?= redis-cli

REDIS_DATA_DIR    ?= $(DB_DATA_ROOT)/redis
REDIS_CONFIG_FILE ?= $(DB_CONFIG_ROOT)/redis.conf
REDIS_PID_FILE    ?= $(REDIS_DATA_DIR)/redis.pid
REDIS_LOG_FILE    ?= $(REDIS_DATA_DIR)/redis.log

REDIS_HOST ?= 0.0.0.0
REDIS_PORT ?=

REDIS_PASSWORD ?=

redis-%: export REDIS_SERVER_BIN := $(REDIS_SERVER_BIN)
redis-%: export REDIS_CLIENT_BIN := $(REDIS_CLIENT_BIN)
redis-%: export REDIS_DATA_DIR := $(REDIS_DATA_DIR)
redis-%: export REDIS_CONFIG_FILE := $(REDIS_CONFIG_FILE)
redis-%: export REDIS_PID_FILE := $(REDIS_PID_FILE)
redis-%: export REDIS_LOG_FILE := $(REDIS_LOG_FILE)
redis-%: export REDIS_HOST := $(REDIS_HOST)
redis-%: export REDIS_PORT := $(REDIS_PORT)
redis-%: export REDIS_PASSWORD := $(REDIS_PASSWORD)

.PHONY: redis-init redis-run redis-start redis-stop redis-status

redis-init:
	@sh "$(DB_ROOT)/scripts/redis.sh" init

redis-run:
	@sh "$(DB_ROOT)/scripts/redis.sh" run

redis-start:
	@sh "$(DB_ROOT)/scripts/redis.sh" start

redis-stop:
	@sh "$(DB_ROOT)/scripts/redis.sh" stop

redis-status:
	@sh "$(DB_ROOT)/scripts/redis.sh" status

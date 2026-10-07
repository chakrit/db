SHELL := /bin/sh
.DEFAULT_GOAL := help

DB_ROOT := $(CURDIR)
include .env
-include .env.local

include make/pg.mk
include make/mariadb.mk
include make/redis.mk
include make/mailcatcher.mk
include make/typesense.mk
include make/garage.mk
include make/rabbitmq.mk

pg-% mariadb-% redis-% mailcatcher-% typesense-% garage-% rabbitmq-%: export DB_ROOT := $(DB_ROOT)
pg-% mariadb-% redis-% mailcatcher-% typesense-% garage-% rabbitmq-%: export DB_DATA_ROOT := $(DB_DATA_ROOT)
pg-% mariadb-% redis-% mailcatcher-% typesense-% garage-% rabbitmq-%: export DB_CONFIG_ROOT := $(DB_CONFIG_ROOT)
pg-% mariadb-% redis-% mailcatcher-% typesense-% garage-% rabbitmq-%: export DB_WAIT_ATTEMPTS := $(DB_WAIT_ATTEMPTS)

.PHONY: help

help:
	@printf '%s\n' 'Services: pg mariadb redis mailcatcher typesense garage rabbitmq' \
		'Tasks: <service>-init, -run (foreground), -start (background), -stop, -status' \
		'MariaDB: mariadb-shell, mariadb-bootstrap, mariadb-logs' \
		'Configuration: .env defaults; .env.local personal overrides; see README.md.' \
		'No task installs software or registers a system service.'

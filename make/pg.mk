#!/usr/bin/make

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

PG_FOLDER   = ./pg
PG_OPTS     = -D $(PG_FOLDER)
PG_LOG_OPTS = -l $(PG_FOLDER)/postgres.log

pg-init:
	mkdir -p $(PG_FOLDER)
	initdb $(PG_OPTS)

pg-run:
	postgres $(PG_OPTS)

pg:
	pg_ctl start $(PG_OPTS) $(PG_LOG_OPTS)

pg-stop:
	pg_ctl stop $(PG_OPTS) $(PG_LOG_OPTS)

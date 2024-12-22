#!/usr/bin/make

MYSQL_WHICH            = $(shell which mysql_install_db)
MYSQL_READLINK         = $(shell readlink $(MYSQL_WHICH))
MYSQL_DIRNAME          = $(shell dirname $(MYSQL_WHICH))
MYSQL_READLINK_DIRNAME = $(shell dirname $(MYSQL_READLINK))

MYSQL_DB      = 'root'
MYSQL_ROOT    = $(shell dirname $(MYSQL_DIRNAME)/$(MYSQL_READLINK_DIRNAME))
MYSQL_FOLDER  = $(abspath ./mysql)
MYSQL_LOGFILE = $(MYSQL_FOLDER)/queries.log
MYSQL_OPTS    = --datadir=$(MYSQL_FOLDER) \
                --basedir=$(MYSQL_ROOT) \
                --user=$(whoami) \

mysql-init:
	mysql_install_db $(MYSQL_OPTS)

mysql-logs:
	cat scripts/mysql-logs.sql | \
		m4 -DMYSQL_DB=$(MYSQL_DB) -DMYSQL_LOGFILE=$(MYSQL_LOGFILE) | \
		mysql -u root
	tail -f $(MYSQL_LOGFILE)

mysql-run:
	mysqld $(MYSQL_OPTS)

mysql:
	mysqld $(MYSQL_OPTS) &

mysql-stop:
	sudo mysqladmin shutdown


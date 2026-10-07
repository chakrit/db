#!/usr/bin/make

REDIS_FOLDER = ./data/redis
REDIS_OPTS   = ./config/redis.conf

redis-run:
	redis-server $(REDIS_OPTS)

redis:
	redis-server $(REDIS_OPTS) &

redis-stop:
	redis-cli SHUTDOWN



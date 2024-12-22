#!/usr/bin/make

REDIS_FOLDER = ./redis
REDIS_OPTS   = ./redis/redis.conf

redis-run:
	redis-server $(REDIS_OPTS)

redis:
	redis-server $(REDIS_OPTS) &

redis-stop:
	redis-cli SHUTDOWN



REDIS_DIR  := ./data/redis
REDIS_OPTS := ./config/redis.conf

.PHONY: redis-init redis-run redis redis-stop

redis-init:
	mkdir -p $(REDIS_DIR)

redis-run:
	redis-server $(REDIS_OPTS) --daemonize no

redis:
	redis-server $(REDIS_OPTS) --daemonize yes \
		--pidfile $(abspath $(REDIS_DIR))/redis.pid --logfile $(abspath $(REDIS_DIR))/redis.log

redis-stop:
	redis-cli SHUTDOWN

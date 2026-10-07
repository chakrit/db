GARAGE_DIR    := ./data/garage
GARAGE_CONFIG := ./config/garage.toml
GARAGE_OPTS   := -c $(GARAGE_CONFIG)

.PHONY: garage-init garage-run garage garage-stop

garage-init:
	mkdir -p $(GARAGE_DIR)/meta $(GARAGE_DIR)/blocks
	@umask 077; test -f $(GARAGE_DIR)/rpc-secret || openssl rand -hex 32 > $(GARAGE_DIR)/rpc-secret

garage-run: | garage-init
	garage $(GARAGE_OPTS) server --single-node

garage: | garage-init
	@nohup garage $(GARAGE_OPTS) server --single-node >> $(GARAGE_DIR)/garage.log 2>&1 < /dev/null & \
		printf '%s\n' "$$!" > $(GARAGE_DIR)/garage.pid; \
		printf 'Garage PID: %s; log: %s\n' "$$!" "$(GARAGE_DIR)/garage.log"

garage-stop:
	kill -TERM "$$(cat $(GARAGE_DIR)/garage.pid)"

RABBITMQ_DIR  := ./data/rabbitmq
RABBITMQ_PATH := $(CURDIR)/$(RABBITMQ_DIR)
RABBITMQ_OPTS := RABBITMQ_MNESIA_BASE="$(RABBITMQ_PATH)/mnesia" \
	RABBITMQ_MNESIA_DIR="$(RABBITMQ_PATH)/mnesia" \
	RABBITMQ_LOG_BASE="$(RABBITMQ_PATH)/log" \
	RABBITMQ_LOGS="$(RABBITMQ_PATH)/log/rabbitmq.log" \
	RABBITMQ_PID_FILE="$(RABBITMQ_PATH)/rabbitmq.pid" \
	RABBITMQ_PLUGINS_EXPAND_DIR="$(RABBITMQ_PATH)/plugins" \
	RABBITMQ_ENABLED_PLUGINS_FILE="$(RABBITMQ_PATH)/enabled_plugins" \
	RABBITMQ_FEATURE_FLAGS_FILE="$(RABBITMQ_PATH)/feature_flags" \
	RABBITMQ_CONFIG_FILE="$(RABBITMQ_PATH)/rabbitmq.conf" \
	RABBITMQ_ADVANCED_CONFIG_FILE="$(RABBITMQ_PATH)/advanced.config" \
	RABBITMQ_CONF_ENV_FILE="$(RABBITMQ_PATH)/rabbitmq-env.conf" \
	ERL_CRASH_DUMP="$(RABBITMQ_PATH)/erl_crash.dump" \
	TMPDIR="$(RABBITMQ_PATH)/tmp" ERL_AFLAGS=-nocookie \
	ERL_EPMD_ADDRESS=127.0.0.1 \
	RABBITMQ_ERLANG_COOKIE="$$(cat $(RABBITMQ_DIR)/.erlang.cookie)"

.PHONY: rabbitmq-init rabbitmq-run rabbitmq rabbitmq-stop

rabbitmq-init:
	mkdir -p $(RABBITMQ_DIR)/mnesia $(RABBITMQ_DIR)/log \
		$(RABBITMQ_DIR)/plugins $(RABBITMQ_DIR)/tmp
	@if [ ! -f $(RABBITMQ_DIR)/.erlang.cookie ]; then \
		umask 077; openssl rand -hex 32 > $(RABBITMQ_DIR)/.erlang.cookie; \
	fi
	chmod 400 $(RABBITMQ_DIR)/.erlang.cookie
	@if [ ! -f $(RABBITMQ_DIR)/enabled_plugins ]; then \
		printf '[].\n' > $(RABBITMQ_DIR)/enabled_plugins; \
	fi

rabbitmq-run: | rabbitmq-init
	$(RABBITMQ_OPTS) rabbitmq-server

rabbitmq: | rabbitmq-init
	$(RABBITMQ_OPTS) rabbitmq-server -detached

rabbitmq-stop:
	$(RABBITMQ_OPTS) rabbitmqctl shutdown
	epmd -kill

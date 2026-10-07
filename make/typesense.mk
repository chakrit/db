TYPESENSE_DIR  := ./data/typesense
TYPESENSE_OPTS := --data-dir=$(TYPESENSE_DIR) --api-key=local-development

.PHONY: typesense-init typesense-run typesense typesense-stop

typesense-init:
	mkdir -p $(TYPESENSE_DIR)

typesense-run:
	typesense-server $(TYPESENSE_OPTS)

typesense:
	@nohup typesense-server $(TYPESENSE_OPTS) >> $(TYPESENSE_DIR)/typesense.log 2>&1 < /dev/null & \
		printf '%s\n' "$$!" > $(TYPESENSE_DIR)/typesense.pid; \
		printf 'Typesense PID: %s; log: %s\n' "$$!" "$(TYPESENSE_DIR)/typesense.log"

typesense-stop:
	kill -TERM "$$(cat $(TYPESENSE_DIR)/typesense.pid)"

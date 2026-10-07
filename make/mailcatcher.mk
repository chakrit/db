MAILCATCHER_DIR  := ./data/mailcatcher
MAILCATCHER_OPTS := TMPDIR="$(abspath $(MAILCATCHER_DIR))/tmp"

.PHONY: mailcatcher-init mailcatcher-run mailcatcher mailcatcher-stop

mailcatcher-init:
	mkdir -p $(MAILCATCHER_DIR)/tmp

mailcatcher-run: | mailcatcher-init
	$(MAILCATCHER_OPTS) mailcatcher --foreground

mailcatcher: | mailcatcher-init
	@$(MAILCATCHER_OPTS) nohup mailcatcher --foreground >> $(MAILCATCHER_DIR)/mailcatcher.log 2>&1 < /dev/null & \
		printf 'MailCatcher PID: %s; log: %s\n' "$$!" "$(MAILCATCHER_DIR)/mailcatcher.log"

mailcatcher-stop:
	curl --fail -X DELETE http://127.0.0.1:1080/

.PHONY: help

help:
	@printf '%s\n' 'Services: pg mariadb redis mailcatcher typesense garage rabbitmq' \
		'make <service>-init | <service>-run | <service> | <service>-stop'

include make/*.mk

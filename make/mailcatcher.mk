#!/usr/bin/make

mc-run:
	mailcatcher --foreground

mailcatcher: | mc
mc:
	mailcatcher

mc-stop:
	curl -v -X DELETE http://0.0.0.0:1080


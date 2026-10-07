#!/usr/bin/make

TS_FOLDER = ./data/typesense
TS_OPTS   = --data-dir="$(TS_FOLDER)" --api-key="$(TS_KEY)"
TS_KEY    = "ad01bafde0e6f32b0051e0b9f02179e8"

typesense: | ts
ts:
	typesense-server $(TS_OPTS)

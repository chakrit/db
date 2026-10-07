#!/bin/sh
set -eu

# shellcheck source=scripts/service.sh
. "${DB_ROOT:?}/scripts/service.sh"

initialize() {
    require_value "$TYPESENSE_DATA_DIR" TYPESENSE_DATA_DIR
    require_value "$TYPESENSE_LOG_DIR" TYPESENSE_LOG_DIR

    umask 077
    mkdir -p "$TYPESENSE_DATA_DIR" "$TYPESENSE_LOG_DIR"
}

validate_endpoint() {
    require_command "$TYPESENSE_CLIENT_BIN"
    require_value "$TYPESENSE_HOST" TYPESENSE_HOST
    require_port "$TYPESENSE_PORT" TYPESENSE_PORT
    client_host=$TYPESENSE_HOST
    if [ "$client_host" = '0.0.0.0' ]; then client_host=127.0.0.1; fi
}

ready() {
    health_response=$("$TYPESENSE_CLIENT_BIN" -q --fail --silent --show-error \
        --noproxy '*' --connect-timeout 1 --max-time 1 \
        "http://$client_host:$TYPESENSE_PORT/health") || return 1
    compact_response=$(printf '%s' "$health_response" | tr -d '[:space:]')
    [ "$compact_response" = '{"ok":true}' ]
}

prepare_run() {
    require_command "$TYPESENSE_SERVER_BIN"
    validate_endpoint
    require_port "$TYPESENSE_PEERING_PORT" TYPESENSE_PEERING_PORT
    [ "$TYPESENSE_PORT" != "$TYPESENSE_PEERING_PORT" ] ||
        fail 'Typesense API and peering ports must differ.'
    require_value "$TYPESENSE_API_KEY" TYPESENSE_API_KEY
    [ -d "$TYPESENSE_DATA_DIR" ] && [ -d "$TYPESENSE_LOG_DIR" ] ||
        fail 'Initialize Typesense with make typesense-init before starting.'

    export TYPESENSE_API_KEY
}

operation=${1:-}
case "$operation" in
    run|start)
        prepare_run
        set -- "$TYPESENSE_SERVER_BIN" --data-dir "$TYPESENSE_DATA_DIR" \
            --log-dir "$TYPESENSE_LOG_DIR" --api-address "$TYPESENSE_HOST" \
            --api-port "$TYPESENSE_PORT" --peering-address 127.0.0.1 \
            --peering-port "$TYPESENSE_PEERING_PORT"
        ;;
esac

case "$operation" in
    init) initialize ;;
    run)
        if ready >/dev/null 2>&1; then fail 'Typesense is already running.'; fi
        exec "$@"
        ;;
    start)
        start_background "$TYPESENSE_LOG_FILE" "$TYPESENSE_PID_FILE" Typesense ready "$@"
        ;;
    stop) stop_background "$TYPESENSE_PID_FILE" Typesense ;;
    status)
        validate_endpoint
        ready
        ;;
    *) fail 'Usage: typesense.sh init|run|start|stop|status' ;;
esac

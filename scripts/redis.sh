#!/bin/sh
set -eu

. "${DB_ROOT:?}/scripts/service.sh"
: "${REDIS_HOST:?}" "${REDIS_PASSWORD?}"

redis_quote_config() {
    case "$1" in
        *'
'*) printf '%s\n' 'Redis configuration values must not contain newlines.' >&2; exit 1 ;;
    esac
    printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

redis_configure() {
    require_value "$REDIS_DATA_DIR" REDIS_DATA_DIR
    [ -f "$REDIS_CONFIG_FILE" ] || {
        printf '%s\n' 'Redis configuration template is missing.' >&2
        exit 1
    }
    redis_template=$(redis_quote_config "$REDIS_CONFIG_FILE")
    redis_data=$(redis_quote_config "$REDIS_DATA_DIR")
    redis_pid=$(redis_quote_config "$REDIS_PID_FILE")
    redis_log=$(redis_quote_config "$REDIS_LOG_FILE")
    redis_bind=$(redis_quote_config "$REDIS_HOST")
    redis_password=$(redis_quote_config "$REDIS_PASSWORD")

    umask 077
    mkdir -p "$REDIS_DATA_DIR"
    redis_runtime_config=$REDIS_DATA_DIR/redis.conf
    : >> "$redis_runtime_config"
    chmod 600 "$redis_runtime_config"
    {
        printf 'include %s\n' "$redis_template"
        printf 'dir %s\n' "$redis_data"
        printf 'pidfile %s\n' "$redis_pid"
        printf 'logfile %s\n' "$redis_log"
        printf 'bind %s\n' "$redis_bind"
        [ -z "$REDIS_PORT" ] || printf 'port %s\n' "$REDIS_PORT"
        printf 'requirepass %s\n' "$redis_password"
    } > "$redis_runtime_config"
}

redis_require_endpoint() {
    require_value "$REDIS_HOST" REDIS_HOST
    require_port "$REDIS_PORT" REDIS_PORT
    require_value "$REDIS_PASSWORD" REDIS_PASSWORD
}

redis_ready() {
    redis_client_host=$REDIS_HOST
    [ "$redis_client_host" != '0.0.0.0' ] || redis_client_host=127.0.0.1
    export REDISCLI_AUTH="$REDIS_PASSWORD"
    redis_reply=$(run_bounded 1 "$REDIS_CLIENT_BIN" \
        -e -t 1 -h "$redis_client_host" -p "$REDIS_PORT" --raw PING) || return
    [ "$redis_reply" = PONG ] || {
        printf '%s\n' 'Redis did not answer PING successfully.' >&2
        return 1
    }
}

redis_run() {
    redis_require_endpoint
    require_command "$REDIS_SERVER_BIN"
    redis_configure

    exec "$REDIS_SERVER_BIN" "$redis_runtime_config" --daemonize no --logfile ''
}

redis_start() {
    redis_require_endpoint
    require_command "$REDIS_SERVER_BIN"
    require_command "$REDIS_CLIENT_BIN"
    redis_configure

    "$REDIS_SERVER_BIN" "$redis_runtime_config" --daemonize yes
    wait_ready Redis redis_ready
}

redis_stop() {
    redis_require_endpoint
    require_command "$REDIS_CLIENT_BIN"
    redis_client_host=$REDIS_HOST
    [ "$redis_client_host" != '0.0.0.0' ] || redis_client_host=127.0.0.1

    REDISCLI_AUTH="$REDIS_PASSWORD" exec "$REDIS_CLIENT_BIN" \
        -e -t 1 -h "$redis_client_host" -p "$REDIS_PORT" SHUTDOWN
}

redis_status() {
    redis_require_endpoint
    require_command "$REDIS_CLIENT_BIN"

    redis_ready
}

case "${1:-}" in
    init) redis_configure ;;
    run) redis_run ;;
    start) redis_start ;;
    stop) redis_stop ;;
    status) redis_status ;;
    *) printf '%s\n' 'Usage: redis.sh init|run|start|stop|status' >&2; exit 2 ;;
esac

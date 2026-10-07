#!/bin/sh
set -eu

. "${DB_ROOT:?}/scripts/service.sh"

rabbitmq_init() {
    require_value "$RABBITMQ_DATA_DIR" RABBITMQ_DATA_DIR
    [ -f "$RABBITMQ_CONFIG_FILE" ] || fail 'RabbitMQ configuration template is missing.'
    if [ ! -f "$RABBITMQ_COOKIE_FILE" ] && [ -d "$RABBITMQ_DATA_DIR/mnesia" ]; then
        rabbit_existing_data=$(find "$RABBITMQ_DATA_DIR/mnesia" -mindepth 1 -print -quit)
        [ -z "$rabbit_existing_data" ] ||
            fail 'Existing RabbitMQ data has no cookie; restore its original cookie before initialization.'
    fi

    umask 077
    mkdir -p "$RABBITMQ_DATA_DIR/mnesia" "$RABBITMQ_DATA_DIR/log" \
        "$RABBITMQ_DATA_DIR/tmp" "$RABBITMQ_DATA_DIR/plugins"
    if [ ! -f "$RABBITMQ_COOKIE_FILE" ]; then
        require_command openssl
        rabbit_new_cookie=$(openssl rand -hex 32)
        printf '%s\n' "$rabbit_new_cookie" > "$RABBITMQ_COOKIE_FILE"
    fi
    chmod 400 "$RABBITMQ_COOKIE_FILE"
    if [ ! -f "$RABBITMQ_DATA_DIR/enabled_plugins" ]; then
        printf '[].\n' > "$RABBITMQ_DATA_DIR/enabled_plugins"
    fi
    if [ ! -f "$RABBITMQ_DATA_DIR/advanced.config" ]; then
        printf '[].\n' > "$RABBITMQ_DATA_DIR/advanced.config"
    fi
    if [ ! -f "$RABBITMQ_DATA_DIR/rabbitmq-env.conf" ]; then
        : > "$RABBITMQ_DATA_DIR/rabbitmq-env.conf"
    fi

    printf '%s\n' 'RabbitMQ directories and cookie are ready; the broker has not been started.'
}

rabbitmq_environment() {
    [ -s "$RABBITMQ_COOKIE_FILE" ] || fail 'Run rabbitmq-init before using RabbitMQ.'
    [ -d "$RABBITMQ_DATA_DIR/tmp" ] || fail 'Run rabbitmq-init before using RabbitMQ.'
    rabbit_cookie=$(cat "$RABBITMQ_COOKIE_FILE")
    case "$rabbit_cookie" in
        ''|*[!a-zA-Z0-9]*) fail 'RabbitMQ cookie must contain only letters and digits.' ;;
    esac

    export RABBITMQ_ERLANG_COOKIE="$rabbit_cookie"
    export RABBITMQ_MNESIA_BASE="$RABBITMQ_DATA_DIR/mnesia"
    export RABBITMQ_MNESIA_DIR="$RABBITMQ_DATA_DIR/mnesia"
    export RABBITMQ_LOG_BASE="$RABBITMQ_DATA_DIR/log"
    export RABBITMQ_LOGS="$RABBITMQ_LOG_FILE"
    export RABBITMQ_PLUGINS_EXPAND_DIR="$RABBITMQ_DATA_DIR/plugins"
    export RABBITMQ_ENABLED_PLUGINS_FILE="$RABBITMQ_DATA_DIR/enabled_plugins"
    export RABBITMQ_FEATURE_FLAGS_FILE="$RABBITMQ_DATA_DIR/feature_flags"
    export RABBITMQ_CONF_ENV_FILE="$RABBITMQ_DATA_DIR/rabbitmq-env.conf"
    export RABBITMQ_ADVANCED_CONFIG_FILE="$RABBITMQ_DATA_DIR/advanced.config"
    export TMPDIR="$RABBITMQ_DATA_DIR/tmp"
    export ERL_CRASH_DUMP="$RABBITMQ_DATA_DIR/erl_crash.dump"
    export ERL_EPMD_ADDRESS=127.0.0.1
    # The native environment cookie override happens after Erlang distribution starts.
    export ERL_AFLAGS="${ERL_AFLAGS:+$ERL_AFLAGS }-nocookie -kernel inet_dist_use_interface {127,0,0,1}"
    unset RABBITMQ_CONFIG_FILES ERL_EPMD_RELAXED_COMMAND_CHECK

    cd "$RABBITMQ_DATA_DIR"
}

rabbitmq_require_endpoint() {
    require_value "$RABBITMQ_HOST" RABBITMQ_HOST
    require_port "$RABBITMQ_PORT" RABBITMQ_PORT
    require_port "$RABBITMQ_DIST_PORT" RABBITMQ_DIST_PORT
    [ "$RABBITMQ_PORT" != "$RABBITMQ_DIST_PORT" ] ||
        fail 'RabbitMQ client and distribution ports must differ.'
}

rabbitmq_ready() {
    run_bounded 5 "$RABBITMQ_CLIENT_BIN" -q -n "$RABBITMQ_NODENAME" --timeout 1 check_running &&
        run_bounded 5 "$RABBITMQ_CLIENT_BIN" -q -n "$RABBITMQ_NODENAME" --timeout 1 \
            check_port_listener "$RABBITMQ_PORT" &&
        run_bounded 5 "$RABBITMQ_CLIENT_BIN" -q -n "$RABBITMQ_NODENAME" --timeout 1 check_port_connectivity
}

rabbitmq_prepare_start() {
    rabbitmq_require_endpoint
    require_value "$RABBITMQ_USER" RABBITMQ_USER
    [ "$RABBITMQ_USER" != guest ] || fail 'Use a RabbitMQ user other than guest for remote access.'
    require_value "$RABBITMQ_PASSWORD" RABBITMQ_PASSWORD
    require_command "$RABBITMQ_SERVER_BIN"
    [ -f "$RABBITMQ_CONFIG_FILE" ] || fail 'RabbitMQ configuration template is missing.'

    rabbitmq_environment
}

rabbitmq_run() {
    rabbitmq_prepare_start

    printf '%s\n' 'RabbitMQ uses the native epmd helper; rabbitmq-stop also stops epmd when idle.'
    exec "$RABBITMQ_SERVER_BIN"
}

rabbitmq_start() {
    rabbitmq_prepare_start
    require_command "$RABBITMQ_CLIENT_BIN"

    "$RABBITMQ_SERVER_BIN" -detached
    wait_ready RabbitMQ rabbitmq_ready
}

rabbitmq_stop() {
    require_command "$RABBITMQ_CONTROL_BIN"
    require_command "$RABBITMQ_EPMD_BIN"
    rabbitmq_environment

    rabbit_epmd_nodes=$(run_bounded 1 "$RABBITMQ_EPMD_BIN" -names)
    rabbit_node_name=${RABBITMQ_NODENAME%%@*}
    case "$rabbit_epmd_nodes" in
        *"name $rabbit_node_name at port "*)
            run_bounded 5 "$RABBITMQ_CONTROL_BIN" -q -n "$RABBITMQ_NODENAME" --timeout 5 shutdown
            rabbit_epmd_nodes=$(run_bounded 1 "$RABBITMQ_EPMD_BIN" -names) ;;
    esac
    case "$rabbit_epmd_nodes" in
        *'name '*)
            printf '%s\n' "$rabbit_epmd_nodes" >&2
            fail 'RabbitMQ stopped; epmd remains because another Erlang node is registered.' ;;
    esac
    run_bounded 1 "$RABBITMQ_EPMD_BIN" -kill
}

rabbitmq_status() {
    rabbitmq_require_endpoint
    require_command "$RABBITMQ_CLIENT_BIN"
    require_command "$RABBITMQ_EPMD_BIN"
    rabbitmq_environment

    rabbit_epmd_nodes=$(run_bounded 1 "$RABBITMQ_EPMD_BIN" -names)
    printf '%s\n' "$rabbit_epmd_nodes"
    rabbit_node_name=${RABBITMQ_NODENAME%%@*}
    case "$rabbit_epmd_nodes" in
        *"name $rabbit_node_name at port "*) ;;
        *) fail 'RabbitMQ is not registered; an idle epmd helper can be stopped with rabbitmq-stop.' ;;
    esac
    rabbitmq_ready
}

case "${1:-}" in
    init) rabbitmq_init ;;
    run) rabbitmq_run ;;
    start) rabbitmq_start ;;
    stop) rabbitmq_stop ;;
    status) rabbitmq_status ;;
    *) fail 'Usage: rabbitmq.sh init|run|start|stop|status' ;;
esac

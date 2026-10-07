#!/bin/sh
set -eu

. "${DB_ROOT:?}/scripts/service.sh"

pg_require_cluster() {
    [ -f "$PG_DATA_DIR/PG_VERSION" ] &&
        [ -f "$PG_DATA_DIR/global/pg_control" ] &&
        [ -d "$PG_DATA_DIR/base" ] &&
        [ -f "$PG_DATA_DIR/postgresql.conf" ] &&
        [ -f "$PG_DATA_DIR/pg_hba.conf" ] || {
        printf '%s\n' 'PostgreSQL data is absent or incomplete; run pg-init.' >&2
        exit 1
    }
}

pg_require_compatible() {
    require_command "$PG_SERVER_BIN"
    pg_reported_version=$("$PG_SERVER_BIN" --version)
    pg_server_major=$(printf '%s\n' "$pg_reported_version" |
        sed -n 's/.*PostgreSQL) \([0-9][0-9]*\).*/\1/p')
    require_value "$pg_server_major" 'PostgreSQL server major version'
    IFS= read -r pg_data_major < "$PG_DATA_DIR/PG_VERSION"
    [ "$pg_server_major" = "$pg_data_major" ] || {
        printf '%s\n' 'PostgreSQL major version differs from existing data; upgrade explicitly.' >&2
        exit 1
    }
}

pg_init() {
    umask 077
    if [ -f "$PG_DATA_DIR/PG_VERSION" ]; then
        pg_require_cluster
        pg_require_compatible
        mkdir -p "$PG_SOCKET_DIR"
        printf '%s\n' 'Existing PostgreSQL cluster retained; authentication was not changed.'
        return
    fi
    if [ -d "$PG_DATA_DIR" ]; then
        pg_existing=$(find "$PG_DATA_DIR" -mindepth 1 -maxdepth 1 -print -quit)
        [ -z "$pg_existing" ] || {
            printf '%s\n' 'PostgreSQL data directory is populated but has no cluster marker.' >&2
            exit 1
        }
    fi
    require_command "$PG_INIT_BIN"
    require_value "$PG_USER" PG_USER
    require_value "$PG_PASSWORD" PG_PASSWORD
    case "$PG_PASSWORD" in
        *'
'*) fail 'PG_PASSWORD must not contain newlines.' ;;
    esac

    mkdir -p "$PG_DATA_DIR"
    printf '%s\n' "$PG_PASSWORD" |
        "$PG_INIT_BIN" -D "$PG_DATA_DIR" --username="$PG_USER" \
            --auth=scram-sha-256 --pwfile=/dev/stdin --encoding=UTF8 \
            --locale=C --no-clean
    printf '%s\n' 'host all all 0.0.0.0/0 scram-sha-256' >> "$PG_DATA_DIR/pg_hba.conf"
    mkdir -p "$PG_SOCKET_DIR"
}

pg_require_endpoint() {
    require_value "$PG_HOST" PG_HOST
    require_port "$PG_PORT" PG_PORT
}

pg_prepare_start() {
    pg_require_endpoint
    pg_require_cluster
    pg_require_compatible
    [ -d "$PG_SOCKET_DIR" ] || {
        printf '%s\n' 'PostgreSQL socket directory is missing; run pg-init.' >&2
        exit 1
    }
}

pg_ready() {
    pg_client_host=$PG_HOST
    [ "$pg_client_host" != '0.0.0.0' ] || pg_client_host=127.0.0.1
    "$PG_CLIENT_BIN" -h "$pg_client_host" -p "$PG_PORT" -U "$PG_USER" -t 1
}

pg_shell_quote() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

pg_run() {
    pg_prepare_start

    exec "$PG_SERVER_BIN" -D "$PG_DATA_DIR" \
        -c "listen_addresses=$PG_HOST" -c "port=$PG_PORT" \
        -c "unix_socket_directories=\"$PG_SOCKET_DIR\"" \
        -c "logging_collector=off"
}

pg_start() {
    pg_prepare_start
    require_command "$PG_CONTROL_BIN"
    require_command "$PG_CLIENT_BIN"
    pg_listener=$(pg_shell_quote "listen_addresses=$PG_HOST")
    pg_port_option=$(pg_shell_quote "port=$PG_PORT")
    pg_socket_option=$(pg_shell_quote "unix_socket_directories=\"$PG_SOCKET_DIR\"")
    pg_server_options="-c $pg_listener -c $pg_port_option -c $pg_socket_option -c logging_collector=off"

    "$PG_CONTROL_BIN" start -D "$PG_DATA_DIR" -p "$PG_SERVER_BIN" \
        -l "$PG_LOG_FILE" -o "$pg_server_options" -w -t 10
    pg_ready
}

pg_stop() {
    pg_require_cluster
    require_command "$PG_CONTROL_BIN"

    exec "$PG_CONTROL_BIN" stop -D "$PG_DATA_DIR" -m fast -w -t 10
}

pg_status() {
    pg_require_endpoint
    pg_require_cluster
    require_command "$PG_CONTROL_BIN"
    require_command "$PG_CLIENT_BIN"

    "$PG_CONTROL_BIN" status -D "$PG_DATA_DIR"
    pg_ready
}

case "${1:-}" in
    init) pg_init ;;
    run) pg_run ;;
    start) pg_start ;;
    stop) pg_stop ;;
    status) pg_status ;;
    *) printf '%s\n' 'Usage: pg.sh init|run|start|stop|status' >&2; exit 2 ;;
esac

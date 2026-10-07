#!/bin/sh
set -eu

# shellcheck source=scripts/service.sh
. "$DB_ROOT/scripts/service.sh"

umask 077
MAILCATCHER_TEMP_DIR=$MAILCATCHER_DATA_DIR/tmp

initialize() {
    mkdir -p "$MAILCATCHER_DATA_DIR" "$MAILCATCHER_TEMP_DIR"
    chmod 700 "$MAILCATCHER_DATA_DIR" "$MAILCATCHER_TEMP_DIR"

    printf 'MailCatcher runtime directory prepared; captured messages are transient.\n'
}

require_initialized() {
    [ -d "$MAILCATCHER_TEMP_DIR" ] || fail 'Run make mailcatcher-init first.'
}

require_ports() {
    require_port "$MAILCATCHER_SMTP_PORT" MAILCATCHER_SMTP_PORT
    require_port "$MAILCATCHER_HTTP_PORT" MAILCATCHER_HTTP_PORT
    [ "$MAILCATCHER_SMTP_PORT" != "$MAILCATCHER_HTTP_PORT" ] ||
        fail 'MailCatcher SMTP and HTTP ports must differ.'
}

server() {
    require_initialized
    require_ports
    require_command "$MAILCATCHER_SERVER_BIN"

    export TMPDIR="$MAILCATCHER_TEMP_DIR"
    exec "$MAILCATCHER_SERVER_BIN" --foreground \
        --smtp-ip "$MAILCATCHER_HOST" --smtp-port "$MAILCATCHER_SMTP_PORT" \
        --http-ip "$MAILCATCHER_HOST" --http-port "$MAILCATCHER_HTTP_PORT"
}

ready() {
    mailcatcher_client_host=$MAILCATCHER_HOST
    [ "$mailcatcher_client_host" != 0.0.0.0 ] || mailcatcher_client_host=127.0.0.1
    "$MAILCATCHER_CLIENT_BIN" -q --fail --silent --show-error --max-time 1 \
        --noproxy '*' "http://$mailcatcher_client_host:$MAILCATCHER_HTTP_PORT/" >/dev/null 2>&1
}

start() {
    require_initialized
    require_ports
    require_command "$MAILCATCHER_SERVER_BIN"
    require_command "$MAILCATCHER_CLIENT_BIN"

    start_background "$MAILCATCHER_LOG_FILE" "$MAILCATCHER_PID_FILE" MailCatcher ready \
        sh "$DB_ROOT/scripts/mailcatcher.sh" run

    printf 'MailCatcher is ready.\n'
}

stop() {
    stop_background "$MAILCATCHER_PID_FILE" MailCatcher
}

status() {
    require_ports
    require_command "$MAILCATCHER_CLIENT_BIN"
    if ! ready; then
        fail "MailCatcher is not ready; inspect $MAILCATCHER_LOG_FILE."
    fi

    printf 'MailCatcher is ready.\n'
}

case "${1:-}" in
    init) initialize ;;
    run) server ;;
    start) start ;;
    stop) stop ;;
    status) status ;;
    *) printf 'Usage: mailcatcher.sh init|run|start|stop|status\n' >&2; exit 1 ;;
esac

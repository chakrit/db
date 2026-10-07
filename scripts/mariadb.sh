#!/bin/sh
set -eu

# shellcheck source=scripts/service.sh
. "$DB_ROOT/scripts/service.sh"

umask 077
MARIADB_DATABASE_DIR=$MARIADB_DATA_DIR/db
MARIADB_TEMP_DIR=$MARIADB_DATA_DIR/tmp
MARIADB_INITIALIZED_FILE=$MARIADB_DATA_DIR/initialized
MARIADB_USER=${MARIADB_USER:-$(id -un)}
MARIADB_HOST=${MARIADB_HOST:-0.0.0.0}

initialize() {
    if [ -e "$MARIADB_INITIALIZED_FILE" ]; then
        require_initialized
        printf 'MariaDB is already initialized.\n'
        return
    fi
    if [ -d "$MARIADB_DATABASE_DIR" ]; then
        for entry in "$MARIADB_DATABASE_DIR"/* "$MARIADB_DATABASE_DIR"/.[!.]* "$MARIADB_DATABASE_DIR"/..?*; do
            if [ -e "$entry" ] || [ -L "$entry" ]; then
                printf 'MariaDB has partial or unrecognized data; preserve it and inspect it.\n' >&2
                return 1
            fi
        done
    fi
    require_command "$MARIADB_INIT_BIN"
    socket_user=$(id -un)

    mkdir -p "$MARIADB_DATABASE_DIR" "$MARIADB_TEMP_DIR"
    chmod 700 "$MARIADB_DATA_DIR" "$MARIADB_DATABASE_DIR" "$MARIADB_TEMP_DIR"
    "$MARIADB_INIT_BIN" --no-defaults "--datadir=$MARIADB_DATABASE_DIR" \
        "--user=$socket_user" --auth-root-authentication-method=socket \
        "--auth-root-socket-user=$socket_user" --skip-test-db

    [ -d "$MARIADB_DATABASE_DIR/mysql" ] || {
        printf 'MariaDB initialization did not create its system database.\n' >&2
        return 1
    }
    printf 'mariadb\n' > "$MARIADB_INITIALIZED_FILE"
    printf 'MariaDB initialized with local Unix socket authentication.\n'
}

require_initialized() {
    if [ ! -f "$MARIADB_INITIALIZED_FILE" ] || [ ! -d "$MARIADB_DATABASE_DIR/mysql" ]; then
        printf 'Run make mariadb-init first; existing data is never initialized automatically.\n' >&2
        return 1
    fi
    initialized_kind=$(cat "$MARIADB_INITIALIZED_FILE")
    if [ "$initialized_kind" != mariadb ]; then
        printf 'This database is not marked as MariaDB; no family conversion is automatic.\n' >&2
        return 1
    fi
}

server() {
    require_initialized
    require_command "$MARIADB_SERVER_BIN"

    set -- --no-defaults "--datadir=$MARIADB_DATABASE_DIR" \
        "--socket=$MARIADB_SOCKET" "--pid-file=$MARIADB_PID_FILE" \
        "--tmpdir=$MARIADB_TEMP_DIR" "--log-error=$MARIADB_LOG_FILE" \
        "--general-log-file=$MARIADB_QUERY_LOG_FILE"
    if [ -z "${MARIADB_PORT:-}" ]; then
        set -- "$@" --skip-networking
    else
        require_port "$MARIADB_PORT" MARIADB_PORT
        set -- "$@" "--bind-address=$MARIADB_HOST" "--port=$MARIADB_PORT"
    fi

    exec "$MARIADB_SERVER_BIN" "$@"
}

ready() {
    run_bounded 1 "$MARIADB_CLIENT_BIN" --no-defaults --protocol=SOCKET \
        "--socket=$MARIADB_SOCKET" "--user=$MARIADB_USER" \
        --connect-timeout=1 --batch --skip-column-names --execute='SELECT 1' >/dev/null 2>&1
}

start() {
    require_initialized
    require_command "$MARIADB_SERVER_BIN"
    require_command "$MARIADB_CLIENT_BIN"
    if [ -n "${MARIADB_PORT:-}" ]; then
        require_port "$MARIADB_PORT" MARIADB_PORT
    fi

    start_background "$MARIADB_LOG_FILE" "$MARIADB_PID_FILE" MariaDB ready \
        sh "$DB_ROOT/scripts/mariadb.sh" run

    printf 'MariaDB is ready.\n'
}

stop() {
    require_initialized
    require_command "$MARIADB_ADMIN_BIN"

    "$MARIADB_ADMIN_BIN" --no-defaults --protocol=SOCKET \
        "--socket=$MARIADB_SOCKET" "--user=$MARIADB_USER" --connect-timeout=1 shutdown
}

status() {
    require_initialized
    require_command "$MARIADB_CLIENT_BIN"

    if ! ready; then
        printf 'MariaDB is not ready; inspect %s.\n' "$MARIADB_LOG_FILE" >&2
        return 1
    fi

    printf 'MariaDB is ready.\n'
}

client() {
    require_initialized
    require_command "$MARIADB_CLIENT_BIN"

    MYSQL_HISTFILE=/dev/null "$MARIADB_CLIENT_BIN" --no-defaults --protocol=SOCKET \
        "--socket=$MARIADB_SOCKET" "--user=$MARIADB_USER" --connect-timeout=1 "$@"
}

bootstrap() {
    require_value "${MARIADB_REMOTE_USER:-}" MARIADB_REMOTE_USER
    require_value "${MARIADB_REMOTE_PASSWORD:-}" MARIADB_REMOTE_PASSWORD
    case "$MARIADB_REMOTE_PASSWORD" in
        *'
'*) printf 'MARIADB_REMOTE_PASSWORD must not contain newlines.\n' >&2; return 1 ;;
    esac
    case "$MARIADB_REMOTE_USER" in
        root|*[!a-zA-Z0-9_]*)
            printf 'MARIADB_REMOTE_USER must be a non-root alphanumeric account name.\n' >&2
            return 1 ;;
    esac
    password_literal=$(printf '%s' "$MARIADB_REMOTE_PASSWORD" | sed "s/'/''/g")

    # Disable SQL backslash escaping before encoding credentials as string literals.
    bootstrap_sql=$(printf "SET SESSION sql_log_off = 1;\nSET SESSION sql_mode = 'NO_BACKSLASH_ESCAPES';\nCREATE USER '%s'@'%%' IDENTIFIED BY '%s';\nGRANT ALL PRIVILEGES ON *.* TO '%s'@'%%';\n" \
        "$MARIADB_REMOTE_USER" "$password_literal" "$MARIADB_REMOTE_USER")
    printf '%s\n' "$bootstrap_sql" | client --batch

    printf 'Authenticated remote development account created.\n'
}

logs() {
    client --batch --execute="SET GLOBAL log_output = 'FILE'; SET GLOBAL general_log = 1;"

    tail -f "$MARIADB_QUERY_LOG_FILE"
}

case "${1:-}" in
    init) initialize ;;
    run) server ;;
    start) start ;;
    stop) stop ;;
    status) status ;;
    bootstrap) bootstrap ;;
    shell) client ;;
    logs) logs ;;
    *) printf 'Usage: mariadb.sh init|run|start|stop|status|bootstrap|shell|logs\n' >&2; exit 1 ;;
esac

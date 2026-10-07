#!/bin/sh
set -eu

# shellcheck source=scripts/service.sh
. "${DB_ROOT:?}/scripts/service.sh"

validate_settings() {
    require_value "$GARAGE_DATA_DIR" GARAGE_DATA_DIR
    require_value "$GARAGE_CONFIG_FILE" GARAGE_CONFIG_FILE
    require_port "$GARAGE_PORT" GARAGE_PORT
    require_port "$GARAGE_RPC_PORT" GARAGE_RPC_PORT
    require_value "$GARAGE_HOST" GARAGE_HOST
    case "$GARAGE_HOST" in
        *[!0-9.]*|'') fail 'GARAGE_HOST must be an IPv4 address' ;;
    esac
    [ "$GARAGE_PORT" != "$GARAGE_RPC_PORT" ] || fail 'Garage S3 and RPC ports must differ'
}

validate_credentials() {
    case "$access_key" in
        GK*) key_hex=${access_key#GK} ;;
        *) fail 'GARAGE_ACCESS_KEY must be GK followed by 32 hexadecimal characters' ;;
    esac
    case "$key_hex" in
        *[!a-fA-F0-9]*) fail 'GARAGE_ACCESS_KEY must contain hexadecimal characters' ;;
    esac
    [ "${#key_hex}" -eq 32 ] || fail 'GARAGE_ACCESS_KEY must be GK followed by 32 hex characters'
    case "$secret_key" in
        *[!a-fA-F0-9]*) fail 'GARAGE_SECRET_KEY must contain hexadecimal characters' ;;
    esac
    [ "${#secret_key}" -eq 64 ] || fail 'GARAGE_SECRET_KEY must have 64 hexadecimal characters'
    case "$bucket" in
        *[!a-z0-9.-]*|*..*|*.-*|*-.*|[!a-z0-9]*|*[!a-z0-9])
            fail 'GARAGE_BUCKET must be a valid S3 bucket name' ;;
    esac
    [ "${#bucket}" -ge 3 ] && [ "${#bucket}" -le 63 ] || fail 'GARAGE_BUCKET length must be 3-63'
}

toml_string() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

require_initialized() {
    [ -d "$GARAGE_DATA_DIR/meta" ] && [ -d "$GARAGE_DATA_DIR/blocks" ] ||
        fail 'Garage metadata or block directory is missing; restore existing state before starting'
    if [ ! -f "$GARAGE_DATA_DIR/meta/db.sqlite" ]; then
        existing_blocks=$(find "$GARAGE_DATA_DIR/blocks" -mindepth 1 -print -quit)
        [ -z "$existing_blocks" ] ||
            fail 'Garage blocks exist without their SQLite metadata; restore metadata before starting'
    fi
    for path in "$GARAGE_CONFIG_FILE" "$GARAGE_DATA_DIR/rpc-secret" \
        "$GARAGE_DATA_DIR/access-key" "$GARAGE_DATA_DIR/secret-key" "$GARAGE_DATA_DIR/bucket"; do
        [ -s "$path" ] || fail 'Garage initialization is incomplete; inspect the instance directory'
    done
    access_key=$(cat "$GARAGE_DATA_DIR/access-key")
    secret_key=$(cat "$GARAGE_DATA_DIR/secret-key")
    bucket=$(cat "$GARAGE_DATA_DIR/bucket")
    validate_credentials
}

initialize() {
    validate_settings
    if [ -e "$GARAGE_CONFIG_FILE" ]; then
        require_initialized
        return
    fi
    for path in "$GARAGE_DATA_DIR"/* "$GARAGE_DATA_DIR"/.[!.]* "$GARAGE_DATA_DIR"/..?*; do
        [ ! -e "$path" ] || fail 'Garage has existing partial state; refusing to replace it'
    done

    require_command openssl
    access_key=${GARAGE_ACCESS_KEY:-}
    secret_key=${GARAGE_SECRET_KEY:-}
    bucket=${GARAGE_BUCKET:-local-bucket}
    if [ -z "$access_key" ]; then access_key="GK$(openssl rand -hex 16)"; fi
    if [ -z "$secret_key" ]; then secret_key=$(openssl rand -hex 32); fi
    validate_credentials
    rpc_secret=$(openssl rand -hex 32)

    umask 077
    mkdir -p "$GARAGE_DATA_DIR/meta" "$GARAGE_DATA_DIR/blocks"
    printf '%s\n' "$rpc_secret" > "$GARAGE_DATA_DIR/rpc-secret"
    printf '%s\n' "$access_key" > "$GARAGE_DATA_DIR/access-key"
    printf '%s\n' "$secret_key" > "$GARAGE_DATA_DIR/secret-key"
    printf '%s\n' "$bucket" > "$GARAGE_DATA_DIR/bucket"
    meta_path=$(toml_string "$GARAGE_DATA_DIR/meta")
    block_path=$(toml_string "$GARAGE_DATA_DIR/blocks")
    secret_path=$(toml_string "$GARAGE_DATA_DIR/rpc-secret")
    cat > "$GARAGE_CONFIG_FILE" <<EOF
metadata_dir = "$meta_path"
data_dir = "$block_path"
db_engine = "sqlite"
replication_factor = 1
rpc_bind_addr = "127.0.0.1:$GARAGE_RPC_PORT"
rpc_public_addr = "127.0.0.1:$GARAGE_RPC_PORT"
rpc_secret_file = "$secret_path"

[s3_api]
s3_region = "garage"
api_bind_addr = "$GARAGE_HOST:$GARAGE_PORT"
EOF
}

ready() {
    run_bounded 1 "$GARAGE_SERVER_BIN" -c "$GARAGE_CONFIG_FILE" health --quiet
}

prepare_run() {
    require_command "$GARAGE_SERVER_BIN"
    validate_settings
    require_initialized
    GARAGE_DEFAULT_ACCESS_KEY=$access_key
    GARAGE_DEFAULT_SECRET_KEY=$secret_key
    GARAGE_DEFAULT_BUCKET=$bucket
    export GARAGE_DEFAULT_ACCESS_KEY GARAGE_DEFAULT_SECRET_KEY GARAGE_DEFAULT_BUCKET
}

case "${1:-}" in
    init) initialize ;;
    run)
        prepare_run
        if ready >/dev/null 2>&1; then fail 'Garage is already running'; fi
        exec "$GARAGE_SERVER_BIN" -c "$GARAGE_CONFIG_FILE" server --single-node --default-bucket
        ;;
    start)
        prepare_run
        start_background "$GARAGE_LOG_FILE" "$GARAGE_PID_FILE" Garage ready \
            "$GARAGE_SERVER_BIN" -c "$GARAGE_CONFIG_FILE" server --single-node --default-bucket
        ;;
    stop)
        require_initialized
        stop_background "$GARAGE_PID_FILE" Garage
        ;;
    status)
        require_command "$GARAGE_SERVER_BIN"
        require_initialized
        ready
        ;;
    *) fail 'Usage: garage.sh init|run|start|stop|status' ;;
esac

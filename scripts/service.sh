#!/bin/sh

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing executable: $1. Install it or configure its *_BIN setting."
}

require_value() {
    [ -n "$1" ] || fail "Set $2 in .env.local or the environment."
}

require_port() {
    case $1 in
        ''|*[!0-9]*) fail "Set $2 to a control-agent-assigned port in 8000–9000." ;;
    esac
    [ "$1" -ge 8000 ] && [ "$1" -le 9000 ] ||
        fail "$2 must be a control-agent-assigned port in 8000–9000."
}

run_bounded() (
    query_limit=$1
    shift
    "$@" &
    query_pid=$!
    (
        sleep "$query_limit"
        if kill -0 "$query_pid" 2>/dev/null; then
            kill -KILL "$query_pid"
        fi
    ) &
    query_timer=$!

    if wait "$query_pid"; then
        query_status=0
    else
        query_status=$?
    fi
    if kill -0 "$query_timer" 2>/dev/null; then
        kill -TERM "$query_timer" || exit 1
    fi
    if wait "$query_timer" 2>/dev/null; then
        timer_status=0
    else
        timer_status=$?
    fi
    case $timer_status in
        0|143) exit "$query_status" ;;
        *) printf 'Readiness timer failed (%s).\n' "$timer_status" >&2; exit 1 ;;
    esac
)

wait_ready() {
    service_label=$1
    readiness_predicate=$2
    readiness_attempt=0
    readiness_limit=${DB_WAIT_ATTEMPTS:-10}
    case $readiness_limit in
        ''|*[!0-9]*) fail 'DB_WAIT_ATTEMPTS must be a positive integer.' ;;
    esac
    [ "$readiness_limit" -gt 0 ] || fail 'DB_WAIT_ATTEMPTS must be positive.'

    while [ "$readiness_attempt" -lt "$readiness_limit" ]; do
        if "$readiness_predicate"; then
            return 0
        fi
        readiness_attempt=$((readiness_attempt + 1))
        if [ "$readiness_attempt" -lt "$readiness_limit" ]; then
            sleep 1
        fi
    done
    printf '%s did not become ready.\n' "$service_label" >&2
    return 1
}

read_pid() {
    [ -s "$1" ] || return 1
    IFS= read -r service_pid < "$1"
    case $service_pid in
        ''|*[!0-9]*) fail "Invalid PID file: $1" ;;
    esac
    [ "$service_pid" -gt 1 ] || fail "Invalid PID in $1"
}

start_background() {
    background_log=$1
    background_pid=$2
    background_label=$3
    background_predicate=$4
    shift 4
    if read_pid "$background_pid" && kill -0 "$service_pid" 2>/dev/null; then
        fail "$background_label is already running (PID $service_pid)."
    fi
    if "$background_predicate"; then
        fail "$background_label is already ready; do not start another process."
    fi

    umask 077
    nohup "$@" >> "$background_log" 2>&1 < /dev/null &
    background_child=$!
    printf '%s\n' "$background_child" > "$background_pid"
    printf '%s starting (PID %s); log: %s\n' "$background_label" "$background_child" "$background_log"

    if wait_ready "$background_label" "$background_predicate"; then
        return 0
    fi
    printf 'Startup failed; inspect %s. PID file: %s\n' "$background_log" "$background_pid" >&2
    if kill -0 "$background_child" 2>/dev/null; then
        stop_background "$background_pid" "$background_label" || return 1
    fi
    return 1
}

stop_background() {
    stopped_pid_file=$1
    stopped_label=$2
    read_pid "$stopped_pid_file" || fail "$stopped_label has no background PID; stop a foreground run with Ctrl-C."
    if ! kill -0 "$service_pid" 2>/dev/null; then
        printf '%s is already stopped.\n' "$stopped_label"
        : > "$stopped_pid_file"
        return 0
    fi

    kill -TERM "$service_pid" || return 1
    stopped_attempt=0
    while kill -0 "$service_pid" 2>/dev/null; do
        stopped_attempt=$((stopped_attempt + 1))
        if [ "$stopped_attempt" -ge "${DB_WAIT_ATTEMPTS:-10}" ]; then
            printf '%s has not stopped; inspect PID %s and its log.\n' "$stopped_label" "$service_pid" >&2
            return 1
        fi
        sleep 1
    done
    : > "$stopped_pid_file"
    printf '%s stopped.\n' "$stopped_label"
}

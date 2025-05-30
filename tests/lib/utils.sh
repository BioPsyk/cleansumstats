#!/usr/bin/env bash
# tests/lib/utils.sh
# Simple utilities for sequential test execution

# Get current timestamp
get_timestamp() {
    date +%s
}

# Format duration in human readable format
format_duration() {
    local duration=$1
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" $hours $minutes $seconds
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" $minutes $seconds
    else
        printf "%ds" $seconds
    fi
}

# Simple logging functions
log_info() {
    echo "[INFO] $*"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Check if a process is still running
is_process_running() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null
}

# Basic cleanup function
cleanup_on_exit() {
    local pids=("$@")
    
    log_info "Cleaning up running processes..."
    
    for pid in "${pids[@]}"; do
        if is_process_running "$pid"; then
            log_debug "Terminating process $pid"
            kill -TERM "$pid" 2>/dev/null || true
            sleep 2
            if is_process_running "$pid"; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
    done
} 
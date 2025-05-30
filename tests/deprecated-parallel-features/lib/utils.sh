#!/usr/bin/env bash
# tests/lib/utils.sh
# Common utility functions for the test infrastructure

# Color codes for output
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly NC='\033[0m' # No Color
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $*" >&2
    fi
}

# Time formatting functions
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

# Get current timestamp in seconds
get_timestamp() {
    date +%s
}

# Get ISO timestamp
get_iso_timestamp() {
    date -Iseconds
}

# Create session directory with proper structure
create_session_dir() {
    local base_dir="$1"
    local session_id="${2:-$(date +%Y%m%d-%H%M%S)}"
    local session_dir="${base_dir}/session-${session_id}"
    
    mkdir -p "${session_dir}/tests" "${session_dir}/status"
    
    # Create symlink to latest session
    ln -sfn "session-${session_id}" "${base_dir}/latest"
    
    echo "$session_dir"
}

# Check if terminal supports fancy output
supports_fancy_output() {
    # In container environments, disable fancy output to avoid tput issues
    if [[ -n "${SINGULARITY_NAME:-}" ]] || [[ -n "${APPTAINER_NAME:-}" ]] || [[ -f "/.dockerenv" ]]; then
        return 1
    fi
    
    # Check if we have a terminal, not a dumb terminal, and tput is available
    [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]] && {
        # Use a subshell to safely check tput availability
        bash -c 'command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1' 2>/dev/null || false
    }
}

# Get terminal width
get_terminal_width() {
    local width=80
    if supports_fancy_output; then
        # Use a subshell to prevent set -euo pipefail from affecting tput
        width=$(bash -c 'tput cols 2>/dev/null || echo 80' 2>/dev/null || echo 80)
    fi
    echo "$width"
}

# Extract test name from file path
extract_test_name() {
    local test_file="$1"
    basename "$test_file" .sh | sed 's/^test_//'
}

# Check if a process is still running
is_process_running() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null
}

# Wait for process with timeout
wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    local count=0
    
    while [[ $count -lt $timeout ]] && is_process_running "$pid"; do
        sleep 1
        ((count++))
    done
    
    ! is_process_running "$pid"
}

# Kill process tree gracefully
kill_process_tree() {
    local pid="$1"
    local signal="${2:-TERM}"
    
    if is_process_running "$pid"; then
        # Kill child processes first
        pkill -"$signal" -P "$pid" 2>/dev/null || true
        # Kill main process
        kill -"$signal" "$pid" 2>/dev/null || true
    fi
}

# Cleanup function for graceful shutdown
cleanup_on_exit() {
    local pids=("$@")
    
    log_info "Cleaning up running processes..."
    
    for pid in "${pids[@]}"; do
        if is_process_running "$pid"; then
            log_debug "Terminating process $pid"
            kill_process_tree "$pid" "TERM"
            
            # Wait for graceful shutdown
            if ! wait_for_process "$pid" 10; then
                log_warn "Force killing process $pid"
                kill_process_tree "$pid" "KILL"
            fi
        fi
    done
    
    # Clean up test environment
    cleanup_test_environment
}

# Clean up test environment
cleanup_test_environment() {
    local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local tests_dir=$(dirname "${script_dir}")
    local temp_bin_dir="${tests_dir}/.temp_bin"
    
    # Remove temporary wrapper directory
    if [[ -d "$temp_bin_dir" ]]; then
        rm -rf "$temp_bin_dir"
        log_debug "Cleaned up temporary Nextflow wrapper"
    fi
}

# Parse test status from status file
get_test_status() {
    local status_file="$1"
    
    if [[ -f "$status_file" ]]; then
        cat "$status_file"
    else
        echo "unknown"
    fi
}

# Calculate ETA based on completed tests and average duration
calculate_eta() {
    local completed="$1"
    local total="$2"
    local avg_duration="$3"
    
    if [[ $completed -eq 0 ]] || [[ $avg_duration -eq 0 ]]; then
        echo "calculating..."
        return
    fi
    
    local remaining=$((total - completed))
    local eta_seconds=$((remaining * avg_duration))
    
    format_duration "$eta_seconds"
}

# Validate required commands are available
check_dependencies() {
    local missing_deps=()
    
    for cmd in timeout date tput; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi
}

# Initialize test environment
init_test_environment() {
    # Check dependencies
    check_dependencies || return 1
    
    # Set default values
    export VERBOSE="${VERBOSE:-false}"
    export TEST_TIMEOUT="${TEST_TIMEOUT:-1800}"
    export MAX_PARALLEL_JOBS="${MAX_PARALLEL_JOBS:-4}"
    
    # Setup Nextflow wrapper for tests to limit resource usage
    setup_test_nextflow_wrapper
    
    # Setup signal handlers for cleanup
    trap 'cleanup_on_exit "${active_pids[@]:-}"' EXIT INT TERM
    
    return 0
}

# Setup Nextflow wrapper to automatically use test configuration
setup_test_nextflow_wrapper() {
    local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local tests_dir=$(dirname "${script_dir}")
    local wrapper_path="${tests_dir}/lib/test-nextflow.sh"
    
    # Create a temporary directory for the wrapper
    local temp_bin_dir="${tests_dir}/.temp_bin"
    mkdir -p "$temp_bin_dir"
    
    # Create a nextflow wrapper that calls our test wrapper
    cat > "${temp_bin_dir}/nextflow" << 'EOF'
#!/usr/bin/env bash
# Temporary wrapper to use test configuration for Nextflow
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${script_dir}")
exec "${tests_dir}/lib/test-nextflow.sh" "$@"
EOF
    
    chmod +x "${temp_bin_dir}/nextflow"
    
    # Add to PATH so it takes precedence over system nextflow
    export PATH="${temp_bin_dir}:${PATH}"
    
    log_debug "Set up Nextflow wrapper for test environment with CPU limits"
} 
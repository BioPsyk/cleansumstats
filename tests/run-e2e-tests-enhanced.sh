#!/usr/bin/env bash
# tests/run-e2e-tests-enhanced.sh
# Enhanced e2e test runner with parallel execution and progress tracking

set -euo pipefail

# Get script directory
test_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source new libraries
source "${test_dir}/lib/utils.sh"
source "${test_dir}/lib/job-manager.sh"
source "${test_dir}/lib/progress-display.sh"

# Initialize test environment
init_test_environment || exit 1

# Default values
specific_test=""
parallel_mode=false
max_parallel_jobs=4
show_progress=true
verbose=false

# Enhanced argument parsing
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --parallel)
                parallel_mode=true
                if [[ $# -gt 1 && $2 =~ ^[0-9]+$ ]]; then
                    max_parallel_jobs=$2
                    shift
                fi
                ;;
            --no-progress)
                show_progress=false
                ;;
            --verbose|-v)
                verbose=true
                export VERBOSE=true
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$specific_test" ]]; then
                    specific_test="$1"
                fi
                ;;
        esac
        shift
    done
}

# Show usage information
show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [TEST_NAME]

Run CleanSumStats e2e tests with enhanced parallel execution and progress tracking.

OPTIONS:
    --parallel [N]      Run tests in parallel with max N jobs (default: 4)
    --no-progress       Disable real-time progress display
    --verbose, -v       Enable verbose output
    --help, -h          Show this help message

EXAMPLES:
    $0                          # Run all tests sequentially
    $0 --parallel               # Run all tests in parallel (4 jobs)
    $0 --parallel 8             # Run all tests in parallel (8 jobs)
    $0 regression_242           # Run specific test
    $0 --parallel --verbose     # Parallel with verbose output

AVAILABLE TESTS:
$(ls "${test_dir}/e2e/"test_*.sh 2>/dev/null | sed 's/.*test_/    /' | sed 's/\.sh$//' | sort || echo "    No tests found")
EOF
}

# Run specific test
run_specific_test() {
    local test_name="$1"
    local log_dir="$2"
    
    local test_file="${test_dir}/e2e/test_${test_name}.sh"
    
    if [[ ! -f "$test_file" ]]; then
        log_error "Test file not found: $test_file"
        echo "Available tests:"
        ls "${test_dir}/e2e/"test_*.sh 2>/dev/null | sed 's/.*test_/  /' | sed 's/\.sh$//' | sort
        return 1
    fi
    
    log_info "Running specific test: $test_name"
    
    # Create simple log structure for single test
    mkdir -p "${log_dir}/tests" "${log_dir}/status"
    
    # Run test with logging
    local start_time=$(get_timestamp)
    local test_log="${log_dir}/tests/${test_name}.log"
    
    {
        echo "=== Test: ${test_name} ==="
        echo "=== Started: $(get_iso_timestamp) ==="
        echo "=== Script: ${test_file} ==="
        echo ""
        
        if timeout "${TEST_TIMEOUT:-1800}" "${test_file}"; then
            local end_time=$(get_timestamp)
            local duration=$((end_time - start_time))
            echo ""
            echo "=== Test completed successfully in ${duration}s ==="
            log_success "Test $test_name passed in $(format_duration $duration)"
            return 0
        else
            local exit_code=$?
            local end_time=$(get_timestamp)
            local duration=$((end_time - start_time))
            echo ""
            echo "=== Test failed with exit code ${exit_code} after ${duration}s ==="
            log_error "Test $test_name failed after $(format_duration $duration)"
            return $exit_code
        fi
    } > "$test_log" 2>&1
}

# Run tests sequentially
run_sequential_tests() {
    local log_dir="$1"
    
    log_info "Running e2e tests sequentially..."
    
    local test_files=("${test_dir}/e2e/"test_*.sh)
    local total=${#test_files[@]}
    local passed=0
    local failed=0
    local start_time=$(get_timestamp)
    
    for test_file in "${test_files[@]}"; do
        local test_name=$(extract_test_name "$test_file")
        
        log_info "Running test: $test_name ($((passed + failed + 1))/$total)"
        
        if run_specific_test "$test_name" "$log_dir"; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    local end_time=$(get_timestamp)
    local total_duration=$((end_time - start_time))
    
    # Show summary
    show_final_summary "$total" "$passed" "$failed" "$total_duration"
    
    return $([[ $failed -eq 0 ]] && echo 0 || echo 1)
}

# Run tests in parallel
run_parallel_tests() {
    local max_jobs="$1"
    local log_dir="$2"
    local show_progress="$3"
    
    log_info "Running e2e tests in parallel (max_parallel=$max_jobs)"
    
    # Initialize progress display
    if [[ "$show_progress" == "true" ]]; then
        init_progress_display true
    else
        init_progress_display false
    fi
    
    # Initialize job manager
    init_job_queue "$max_jobs" "$log_dir"
    
    # Queue all tests
    local test_files=("${test_dir}/e2e/"test_*.sh)
    for test_file in "${test_files[@]}"; do
        local test_name=$(extract_test_name "$test_file")
        add_job_to_queue "$test_name" "$test_file"
    done
    
    # Start execution with progress monitoring
    local start_time=$(get_timestamp)
    execute_job_queue_with_progress "$show_progress"
    local end_time=$(get_timestamp)
    local total_duration=$((end_time - start_time))
    
    # Get final statistics
    local stats=$(get_job_stats)
    local total=$(echo "$stats" | grep -o 'total:[0-9]*' | cut -d: -f2)
    local passed=$(echo "$stats" | grep -o 'passed:[0-9]*' | cut -d: -f2)
    local failed=$(echo "$stats" | grep -o 'failed:[0-9]*' | cut -d: -f2)
    
    # Show final summary
    show_final_summary "$total" "$passed" "$failed" "$total_duration"
    
    # Generate detailed summary
    generate_execution_summary
    
    return $([[ $failed -eq 0 ]] && echo 0 || echo 1)
}

# Generate execution summary
generate_execution_summary() {
    local session_id=$(basename "$SESSION_LOG_DIR" | sed 's/session-//')
    local stats=$(get_job_stats)
    local total=$(echo "$stats" | grep -o 'total:[0-9]*' | cut -d: -f2)
    local passed=$(echo "$stats" | grep -o 'passed:[0-9]*' | cut -d: -f2)
    local failed=$(echo "$stats" | grep -o 'failed:[0-9]*' | cut -d: -f2)
    
    # Create JSON summary
    cat > "${SESSION_LOG_DIR}/summary.json" <<EOF
{
  "session_id": "$session_id",
  "timestamp": "$(get_iso_timestamp)",
  "test_type": "e2e",
  "total_tests": $total,
  "passed": $passed,
  "failed": $failed,
  "parallel_jobs": $MAX_PARALLEL,
  "failed_tests": [$(get_failed_jobs | sed 's/.*/"&"/' | paste -sd, -)],
  "success_rate": $(echo "scale=2; $passed * 100 / $total" | bc -l 2>/dev/null || echo "0")
}
EOF
    
    log_info "Execution summary saved to ${SESSION_LOG_DIR}/summary.json"
}

# Main execution function
main() {
    parse_arguments "$@"
    
    # Setup session logging
    local session_id=$(date +%Y%m%d-%H%M%S)
    local log_dir="${test_dir}/test_logs/session-${session_id}"
    
    # Create session directory
    log_dir=$(create_session_dir "${test_dir}/test_logs" "$session_id")
    export SESSION_LOG_DIR="$log_dir"
    
    log_info "Starting e2e test execution (session: $session_id)"
    log_info "Logs will be saved to: $log_dir"
    
    # Run tests based on mode
    if [[ -n "$specific_test" ]]; then
        run_specific_test "$specific_test" "$log_dir"
    elif [[ "$parallel_mode" == "true" ]]; then
        run_parallel_tests "$max_parallel_jobs" "$log_dir" "$show_progress"
    else
        run_sequential_tests "$log_dir"
    fi
}

# Cleanup on exit
cleanup() {
    if [[ "${SESSION_LOG_DIR:-}" != "" ]] && [[ -d "$SESSION_LOG_DIR" ]]; then
        # Kill any remaining jobs
        kill_all_jobs 2>/dev/null || true
    fi
    
    # Cleanup progress display
    cleanup_progress_display 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Run main function
main "$@" 
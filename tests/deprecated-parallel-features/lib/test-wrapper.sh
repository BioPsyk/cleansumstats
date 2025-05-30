#!/usr/bin/env bash
# tests/lib/test-wrapper.sh
# Standardized test execution wrapper

# Source utilities
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/utils.sh"

# Run test with standardized logging
run_test_with_logging() {
    local test_name="$1"
    local test_script="$2"
    local log_dir="$3"
    
    # Create test-specific log file
    local test_log="${log_dir}/tests/${test_name}.log"
    mkdir -p "$(dirname "$test_log")"
    
    # Start time tracking
    local start_time=$(get_timestamp)
    echo "${test_name}-started" > "${log_dir}/status/${test_name}.status"
    
    # Execute test with full logging
    {
        echo "=== Test: ${test_name} ==="
        echo "=== Started: $(get_iso_timestamp) ==="
        echo "=== Script: ${test_script} ==="
        echo ""
        
        # Run the actual test
        if timeout "${TEST_TIMEOUT:-1800}" "${test_script}"; then
            local end_time=$(get_timestamp)
            local duration=$((end_time - start_time))
            echo ""
            echo "=== Test completed successfully in ${duration}s ==="
            echo "${test_name}-succeeded" > "${log_dir}/status/${test_name}.status"
            echo "${test_name}-succeeded" >&2  # For orchestrator
            exit 0
        else
            local exit_code=$?
            local end_time=$(get_timestamp)
            local duration=$((end_time - start_time))
            echo ""
            echo "=== Test failed with exit code ${exit_code} after ${duration}s ==="
            echo "${test_name}-failed" > "${log_dir}/status/${test_name}.status"
            echo "${test_name}-failed" >&2  # For orchestrator
            exit $exit_code
        fi
    } > "$test_log" 2>&1
}

# Run single test (for direct execution)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 3 ]]; then
        echo "Usage: $0 <test_name> <test_script> <log_dir>" >&2
        exit 1
    fi
    
    run_test_with_logging "$1" "$2" "$3"
fi 
#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source new libraries if available
if [[ -f "${test_dir}/lib/utils.sh" ]]; then
    source "${test_dir}/lib/utils.sh"
    source "${test_dir}/lib/job-manager.sh"
    source "${test_dir}/lib/progress-display.sh"
    ENHANCED_MODE=true
else
    ENHANCED_MODE=false
fi

# Parse arguments
specific_test=""
parallel_mode=false
max_parallel_jobs=4  # Increased default
show_progress=true
verbose=false

# Enhanced argument parsing
while [[ $# -gt 0 ]]; do
  arg="$1"
  case $arg in
    --parallel)
      parallel_mode=true
      shift
      # Check if next argument is a number
      if [[ $# -gt 0 && $1 =~ ^[0-9]+$ ]]; then
        max_parallel_jobs=$1
        shift
      fi
      ;;
    --no-progress)
      show_progress=false
      shift
      ;;
    --verbose|-v)
      verbose=true
      export VERBOSE=true
      shift
      ;;
    *)
      if [ -z "$specific_test" ]; then
        specific_test="$arg"
      fi
      shift
      ;;
  esac
done

# Enhanced parallel execution using new infrastructure
run_enhanced_parallel() {
    local max_jobs="$1"
    local show_progress="$2"
    
    # Initialize test environment
    echo "DEBUG: About to call init_test_environment" >&2
    if init_test_environment; then
        echo "DEBUG: init_test_environment succeeded" >&2
    else
        echo "DEBUG: init_test_environment failed, returning" >&2
        return 1
    fi
    
    # Setup session logging
    echo "DEBUG: Setting up session logging" >&2
    local session_id=$(date +%Y%m%d-%H%M%S)
    local log_dir=$(create_session_dir "${test_dir}/test_logs" "$session_id")
    export SESSION_LOG_DIR="$log_dir"
    echo "DEBUG: Session log dir: $log_dir" >&2
    
    if [[ "$verbose" == "true" ]]; then
        log_info "Starting enhanced parallel e2e test execution (session: $session_id)"
        log_info "Max parallel jobs: $max_jobs"
        log_info "Logs will be saved to: $log_dir"
    fi
    
    # Initialize progress display
    echo "DEBUG: Initializing progress display" >&2
    if [[ "$show_progress" == "true" ]]; then
        init_progress_display true
    else
        init_progress_display false
    fi
    echo "DEBUG: Progress display initialized" >&2
    
    # Initialize job manager
    echo "DEBUG: Initializing job manager" >&2
    init_job_queue "$max_jobs" "$log_dir"
    echo "DEBUG: Job manager initialized" >&2
    
    # Queue all tests
    local test_files=("${test_dir}/e2e/"test_*.sh)
    echo "DEBUG: Found ${#test_files[@]} test files" >&2
    for test_file in "${test_files[@]}"; do
        local test_name=$(extract_test_name "$test_file")
        echo "DEBUG: Queuing test: $test_name from $test_file" >&2
        add_job_to_queue "$test_name" "$test_file"
    done
    echo "DEBUG: Queued $TOTAL_JOBS tests" >&2
    
    # Start execution with progress monitoring
    echo "DEBUG: About to start execution with progress monitoring" >&2
    local start_time=$(get_timestamp)
    echo "DEBUG: Calling execute_job_queue_with_progress with show_progress=$show_progress" >&2
    execute_job_queue_with_progress "$show_progress"
    echo "DEBUG: execute_job_queue_with_progress completed" >&2
    local end_time=$(get_timestamp)
    local total_duration=$((end_time - start_time))
    
    # Get final statistics
    local stats=$(get_job_stats)
    local total=$(echo "$stats" | grep -o 'total:[0-9]*' | cut -d: -f2)
    local passed=$(echo "$stats" | grep -o 'passed:[0-9]*' | cut -d: -f2)
    local failed=$(echo "$stats" | grep -o 'failed:[0-9]*' | cut -d: -f2)
    
    # Show final summary
    show_final_summary "$total" "$passed" "$failed" "$total_duration"
    
    # Return appropriate exit code
    return $([[ $failed -eq 0 ]] && echo 0 || echo 1)
}

# Legacy parallel execution (fallback)
run_legacy_parallel() {
    local max_jobs="$1"
    
    echo "Running e2e tests in parallel (max ${max_jobs} jobs)..."
    pids=()
    test_files=("${test_dir}/e2e/"test_*.sh)
    
    for test_file in "${test_files[@]}"; do
      test_name=$(basename "$test_file" .sh)
      
      # Wait if we've reached the maximum number of parallel jobs
      while [ ${#pids[@]} -ge $max_jobs ]; do
        # Check for completed jobs
        new_pids=()
        for pid in "${pids[@]}"; do
          if kill -0 "$pid" 2>/dev/null; then
            new_pids+=("$pid")
          fi
        done
        pids=("${new_pids[@]}")
        
        # Small delay to avoid busy waiting
        if [ ${#pids[@]} -ge $max_jobs ]; then
          sleep 0.1
        fi
      done
      
      echo "Starting $test_name in background..."
      (
        echo "=== Running $test_name ==="
        if "${test_file}"; then
          echo "=== $test_name PASSED ==="
        else
          echo "=== $test_name FAILED ==="
          exit 1
        fi
      ) &
      pids+=($!)
    done
    
    # Wait for all remaining tests to complete and collect results
    failed_tests=()
    for i in "${!pids[@]}"; do
      if ! wait "${pids[$i]}"; then
        test_name=$(basename "${test_files[$i]}" .sh)
        failed_tests+=("$test_name")
      fi
    done
    
    # Report results
    if [ ${#failed_tests[@]} -eq 0 ]; then
      echo "All e2e tests passed!"
      return 0
    else
      echo "Failed tests: ${failed_tests[*]}"
      return 1
    fi
}

# Check if a specific test is provided
if [ -n "$specific_test" ]; then
  test_file="${test_dir}/e2e/test_${specific_test}.sh"
  
  if [ -f "${test_file}" ]; then
    echo "Running specific test: ${specific_test}"
    "${test_file}"
  else
    echo "Error: Test file ${test_file} not found"
    echo "Available tests:"
    ls "${test_dir}/e2e/"test_*.sh | sed 's/.*test_//' | sed 's/\.sh$//' | sort
    exit 1
  fi
else
  # Run all tests
  if [ "$parallel_mode" = true ]; then
    if [[ "$ENHANCED_MODE" == "true" ]]; then
        # Use enhanced parallel execution
        run_enhanced_parallel "$max_parallel_jobs" "$show_progress"
    else
        # Use legacy parallel execution
        run_legacy_parallel "$max_parallel_jobs"
    fi
  else
    # Run tests sequentially
    for test_file in "${test_dir}/e2e/"test_*.sh
    do
      "${test_file}"
    done
  fi
fi

# run only one regression test
#${test_dir}/e2e/test_regression_missing_variants.sh



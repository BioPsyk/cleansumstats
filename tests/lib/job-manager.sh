#!/usr/bin/env bash
# tests/lib/job-manager.sh
# Parallel job management for test execution

# Source utilities
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/utils.sh"
source "${script_dir}/progress-display.sh"

# Global job tracking variables
declare -g -A JOB_STATES=()      # test_name -> QUEUED|RUNNING|COMPLETED|FAILED
declare -g -A JOB_PIDS=()        # test_name -> process_id
declare -g -A JOB_START_TIMES=() # test_name -> start_timestamp
declare -g -A JOB_SCRIPTS=()     # test_name -> script_path

declare -g -a JOB_QUEUE=()       # Array of queued test names
declare -g -a RUNNING_JOBS=()    # Array of currently running test names
declare -g -a COMPLETED_JOBS=()  # Array of completed test names
declare -g -a FAILED_JOBS=()     # Array of failed test names

declare -g MAX_PARALLEL=4
declare -g SESSION_LOG_DIR=""
declare -g TOTAL_JOBS=0

# Initialize job queue and management
init_job_queue() {
    local max_parallel="${1:-4}"
    local log_dir="$2"
    
    MAX_PARALLEL="$max_parallel"
    SESSION_LOG_DIR="$log_dir"
    
    # Clear all tracking arrays
    JOB_STATES=()
    JOB_PIDS=()
    JOB_START_TIMES=()
    JOB_SCRIPTS=()
    JOB_QUEUE=()
    RUNNING_JOBS=()
    COMPLETED_JOBS=()
    FAILED_JOBS=()
    
    TOTAL_JOBS=0
    
    # Create necessary directories
    mkdir -p "${SESSION_LOG_DIR}/tests" "${SESSION_LOG_DIR}/status"
    
    # Initialize log files
    touch "${SESSION_LOG_DIR}/timing.log"
    touch "${SESSION_LOG_DIR}/completions.log"
    
    log_debug "Job queue initialized with max_parallel=$MAX_PARALLEL"
}

# Add a test to the job queue
add_job_to_queue() {
    local test_name="$1"
    local test_script="$2"
    
    JOB_QUEUE+=("$test_name")
    JOB_STATES["$test_name"]="QUEUED"
    JOB_SCRIPTS["$test_name"]="$test_script"
    
    ((TOTAL_JOBS++))
    
    log_debug "Added job to queue: $test_name"
}

# Start the next available job from the queue
start_next_job() {
    # Check if we can start more jobs
    if [[ ${#RUNNING_JOBS[@]} -ge $MAX_PARALLEL ]] || [[ ${#JOB_QUEUE[@]} -eq 0 ]]; then
        return 1
    fi
    
    # Get next job from queue
    local test_name="${JOB_QUEUE[0]}"
    local test_script="${JOB_SCRIPTS[$test_name]}"
    
    # Remove from queue
    JOB_QUEUE=("${JOB_QUEUE[@]:1}")
    
    # Start the job
    spawn_test_worker "$test_name" "$test_script"
    
    return 0
}

# Spawn a test worker process
spawn_test_worker() {
    local test_name="$1"
    local test_script="$2"
    local log_file="${SESSION_LOG_DIR}/tests/${test_name}.log"
    
    # Record start time
    local start_time=$(get_timestamp)
    JOB_START_TIMES["$test_name"]="$start_time"
    record_test_start "$test_name"
    
    # Update state
    JOB_STATES["$test_name"]="RUNNING"
    RUNNING_JOBS+=("$test_name")
    
    log_debug "Starting test: $test_name"
    
    # Create wrapper script for the test
    local wrapper_script="${SESSION_LOG_DIR}/status/${test_name}.wrapper.sh"
    cat > "$wrapper_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

test_name="$1"
test_script="$2"
log_file="$3"
start_time="$4"
session_log_dir="$5"

# Create test log with header
{
    echo "=== Test: $test_name ==="
    echo "=== Started: $(date -Iseconds) ==="
    echo "=== Script: $test_script ==="
    echo ""
    
    # Run the actual test with timeout
    if timeout ${TEST_TIMEOUT:-1800} "$test_script"; then
        exit_code=0
    else
        exit_code=$?
    fi
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo "=== Test completed successfully in ${duration}s ==="
        echo "${test_name}-succeeded" > "${session_log_dir}/status/${test_name}.status"
        echo "${test_name}-succeeded" >&2
    else
        echo "=== Test failed with exit code $exit_code after ${duration}s ==="
        echo "${test_name}-failed" > "${session_log_dir}/status/${test_name}.status"
        echo "${test_name}-failed" >&2
    fi
    
    # Record timing
    echo "${test_name},${duration}" >> "${session_log_dir}/timing.log"
    
    exit $exit_code
} > "$log_file" 2>&1
EOF
    
    chmod +x "$wrapper_script"
    
    # Start the test in background
    "$wrapper_script" "$test_name" "$test_script" "$log_file" "$start_time" "$SESSION_LOG_DIR" &
    local pid=$!
    
    JOB_PIDS["$test_name"]="$pid"
    
    log_debug "Started test $test_name with PID $pid"
}

# Monitor running jobs and handle completions
monitor_running_jobs() {
    local updated=false
    
    for i in "${!RUNNING_JOBS[@]}"; do
        local test_name="${RUNNING_JOBS[$i]}"
        local pid="${JOB_PIDS[$test_name]}"
        
        # Check if process is still running
        if ! is_process_running "$pid"; then
            # Process completed, check exit status
            wait "$pid" 2>/dev/null
            local exit_code=$?
            
            # Calculate duration
            local start_time="${JOB_START_TIMES[$test_name]}"
            local end_time=$(get_timestamp)
            local duration=$((end_time - start_time))
            
            # Update state based on exit code
            if [[ $exit_code -eq 0 ]]; then
                JOB_STATES["$test_name"]="COMPLETED"
                COMPLETED_JOBS+=("$test_name")
                log_test_completion "$test_name" "passed" "$duration"
                log_debug "Test completed successfully: $test_name (${duration}s)"
            else
                JOB_STATES["$test_name"]="FAILED"
                FAILED_JOBS+=("$test_name")
                log_test_completion "$test_name" "failed" "$duration"
                log_debug "Test failed: $test_name (exit code: $exit_code, duration: ${duration}s)"
            fi
            
            log_test_timing "$test_name" "$duration"
            
            # Remove from running jobs
            unset RUNNING_JOBS[$i]
            RUNNING_JOBS=("${RUNNING_JOBS[@]}")  # Reindex array
            
            # Clean up
            unset JOB_PIDS["$test_name"]
            
            updated=true
        fi
    done
    
    return $([ "$updated" = true ] && echo 0 || echo 1)
}

# Execute job queue with progress monitoring
execute_job_queue_with_progress() {
    local show_progress="${1:-true}"
    
    log_info "Starting parallel test execution (max_parallel=$MAX_PARALLEL, total_jobs=$TOTAL_JOBS)"
    
    # Start initial batch of jobs
    while start_next_job; do
        :  # Keep starting jobs until we hit the limit or run out
    done
    
    # Main monitoring loop
    while [[ ${#RUNNING_JOBS[@]} -gt 0 ]] || [[ ${#JOB_QUEUE[@]} -gt 0 ]]; do
        # Monitor running jobs
        if monitor_running_jobs; then
            # Jobs completed, try to start new ones
            while start_next_job; do
                :
            done
        fi
        
        # Update progress display
        if [[ "$show_progress" == "true" ]]; then
            local started=$TOTAL_JOBS
            local running=${#RUNNING_JOBS[@]}
            local completed=${#COMPLETED_JOBS[@]}
            local failed=${#FAILED_JOBS[@]}
            local queued=${#JOB_QUEUE[@]}
            
            update_progress_display "$started" "$running" "$completed" "$failed" "$queued" "${RUNNING_JOBS[@]}"
        fi
        
        # Brief sleep to avoid busy waiting
        sleep 1
    done
    
    # Final progress update
    if [[ "$show_progress" == "true" ]]; then
        local started=$TOTAL_JOBS
        local running=0
        local completed=${#COMPLETED_JOBS[@]}
        local failed=${#FAILED_JOBS[@]}
        local queued=0
        
        update_progress_display "$started" "$running" "$completed" "$failed" "$queued"
    fi
    
    log_info "Test execution completed: $TOTAL_JOBS total, ${#COMPLETED_JOBS[@]} passed, ${#FAILED_JOBS[@]} failed"
}

# Kill all running jobs gracefully
kill_all_jobs() {
    log_info "Terminating all running jobs..."
    
    for test_name in "${RUNNING_JOBS[@]}"; do
        local pid="${JOB_PIDS[$test_name]:-}"
        
        if [[ -n "$pid" ]] && is_process_running "$pid"; then
            log_debug "Terminating job: $test_name (PID: $pid)"
            kill_process_tree "$pid" "TERM"
            
            # Wait briefly for graceful shutdown
            if ! wait_for_process "$pid" 5; then
                log_debug "Force killing job: $test_name (PID: $pid)"
                kill_process_tree "$pid" "KILL"
            fi
            
            # Mark as failed
            JOB_STATES["$test_name"]="FAILED"
            FAILED_JOBS+=("$test_name")
        fi
    done
    
    # Clear running jobs
    RUNNING_JOBS=()
}

# Get job statistics
get_job_stats() {
    local total=$TOTAL_JOBS
    local running=${#RUNNING_JOBS[@]}
    local completed=${#COMPLETED_JOBS[@]}
    local failed=${#FAILED_JOBS[@]}
    local queued=${#JOB_QUEUE[@]}
    local passed=$((completed - failed))
    
    echo "total:$total running:$running completed:$completed failed:$failed queued:$queued passed:$passed"
}

# Check if all jobs are complete
all_jobs_complete() {
    [[ ${#RUNNING_JOBS[@]} -eq 0 ]] && [[ ${#JOB_QUEUE[@]} -eq 0 ]]
}

# Get failed job names
get_failed_jobs() {
    printf '%s\n' "${FAILED_JOBS[@]}"
}

# Get completed job names
get_completed_jobs() {
    printf '%s\n' "${COMPLETED_JOBS[@]}"
}

# Retry failed jobs
retry_failed_jobs() {
    local max_retries="${1:-1}"
    
    if [[ ${#FAILED_JOBS[@]} -eq 0 ]]; then
        log_info "No failed jobs to retry"
        return 0
    fi
    
    log_info "Retrying ${#FAILED_JOBS[@]} failed jobs (max_retries=$max_retries)"
    
    # Move failed jobs back to queue
    for test_name in "${FAILED_JOBS[@]}"; do
        JOB_QUEUE+=("$test_name")
        JOB_STATES["$test_name"]="QUEUED"
    done
    
    # Clear failed jobs list
    FAILED_JOBS=()
    
    # Execute retry
    execute_job_queue_with_progress true
}

# Generate execution summary
generate_execution_summary() {
    local session_id=$(basename "$SESSION_LOG_DIR" | sed 's/session-//')
    local total=$TOTAL_JOBS
    local passed=${#COMPLETED_JOBS[@]}
    local failed=${#FAILED_JOBS[@]}
    
    # Calculate total duration
    local start_time=$(head -n1 "${SESSION_LOG_DIR}/timing.log" 2>/dev/null | cut -d',' -f2 || echo "0")
    local end_time=$(tail -n1 "${SESSION_LOG_DIR}/timing.log" 2>/dev/null | cut -d',' -f2 || echo "0")
    local total_duration=0
    
    if [[ -f "${SESSION_LOG_DIR}/timing.log" ]]; then
        while IFS=',' read -r test_name duration; do
            if [[ "$duration" =~ ^[0-9]+$ ]]; then
                total_duration=$((total_duration + duration))
            fi
        done < "${SESSION_LOG_DIR}/timing.log"
    fi
    
    # Create JSON summary
    cat > "${SESSION_LOG_DIR}/summary.json" <<EOF
{
  "session_id": "$session_id",
  "timestamp": "$(get_iso_timestamp)",
  "total_tests": $total,
  "passed": $passed,
  "failed": $failed,
  "duration": $total_duration,
  "parallel_jobs": $MAX_PARALLEL,
  "failed_tests": [$(printf '"%s",' "${FAILED_JOBS[@]}" | sed 's/,$//')],
  "completed_tests": [$(printf '"%s",' "${COMPLETED_JOBS[@]}" | sed 's/,$//')],
  "success_rate": $(echo "scale=2; $passed * 100 / $total" | bc -l 2>/dev/null || echo "0")
}
EOF
    
    # Create human-readable summary
    cat > "${SESSION_LOG_DIR}/summary.txt" <<EOF
CleanSumStats Test Execution Summary
====================================
Session: $session_id
Date: $(date)
Duration: $(format_duration $total_duration)

Results:
  Total Tests: $total
  Passed: $passed
  Failed: $failed
  Success Rate: $(echo "scale=1; $passed * 100 / $total" | bc -l 2>/dev/null || echo "0")%

Performance:
  Parallel Jobs: $MAX_PARALLEL
  Average Test Duration: $(echo "scale=1; $total_duration / $total" | bc -l 2>/dev/null || echo "0")s

$(if [[ $failed -gt 0 ]]; then
    echo "Failed Tests:"
    for test in "${FAILED_JOBS[@]}"; do
        echo "  - $test"
    done
fi)

Logs available in: $SESSION_LOG_DIR
EOF
    
    log_info "Execution summary saved to ${SESSION_LOG_DIR}/summary.{json,txt}"
} 
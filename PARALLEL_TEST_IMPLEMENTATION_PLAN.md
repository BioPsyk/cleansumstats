# 🚀 Parallel Test Execution Implementation Plan

## 📋 Overview

This plan implements robust parallel test execution with real-time progress tracking for CleanSumStats, working within the existing `cleansumstats.sh` infrastructure with minimal changes.

### 🎯 Goals
- **Robust parallel execution** for test, utest, and etest modes
- **Real-time progress display** with updating counters (no new lines)
- **Detailed logging** to `tests/test_logs/` (not `tmp/`)
- **Clean stdout** showing only progress and summary
- **Minimal changes** to existing `cleansumstats.sh` flow
- **Backward compatibility** with existing test infrastructure

### 📊 Current State Analysis

**Existing Test Structure:**
- **E2E Tests:** 21 tests (regression tests + cases)
- **Unit Tests:** 25+ tests (various pipeline components)
- **Current Parallel:** Basic implementation in `run-e2e-tests.sh`
- **Logging:** Individual test logs to `test_logs/` (recently added)
- **Container:** Singularity with proper mounting already implemented

## 🏗️ Implementation Strategy

### Phase 1: Enhanced Test Infrastructure (Minimal Changes)

#### 1.1 Directory Structure
```
tests/
├── lib/                          # NEW: Shared utilities
│   ├── progress-display.sh       # Real-time progress UI
│   ├── job-manager.sh            # Parallel job management
│   ├── test-wrapper.sh           # Individual test wrapper
│   └── utils.sh                  # Common utilities
├── test_logs/                    # ENHANCED: Structured logging
│   ├── session-YYYYMMDD-HHMMSS/  # Session-based organization
│   │   ├── orchestrator.log      # Main orchestrator log
│   │   ├── progress.log          # Progress tracking
│   │   ├── summary.json          # Machine-readable summary
│   │   └── tests/               # Individual test logs
│   │       ├── regression_242.log
│   │       └── ...
│   └── latest -> session-*/      # Symlink to latest session
├── run-e2e-tests.sh             # ENHANCED: Uses new infrastructure
├── run-unit-tests.sh            # ENHANCED: Parallel support
└── run-tests.sh                 # ENHANCED: Coordinated execution
```

#### 1.2 cleansumstats.sh Changes (Minimal)
```bash
# ONLY CHANGE: Update test_logs mounting path
testlogs_host="${project_dir}/tests/test_logs"
testlogs_container="/cleansumstats/tests/test_logs"

# ONLY CHANGE: Create tests/test_logs directory
elif [ "${runtype}" == "test" ]; then
  mkdir -p tests/test_logs  # Changed from test_logs
  # ... rest unchanged
```

### Phase 2: Core Components Implementation

#### 2.1 Progress Display Manager (`tests/lib/progress-display.sh`)

**Features:**
- ANSI escape sequences for in-place updates
- Terminal width detection and responsive layout
- Color-coded status indicators
- Progress bar with percentage and ETA
- Fallback for non-interactive terminals

**Example Output:**
```
┌─────────────────────────────────────────────────────────────┐
│ CleanSumStats Test Suite - Parallel Execution              │
├─────────────────────────────────────────────────────────────┤
│ Progress: ████████████████████░░░░░░░░ 75% (15/20)          │
│                                                             │
│ Status:  🟢 Started: 20  🔵 Running: 3  ✅ Passed: 12      │
│          ❌ Failed: 0   ⏸️  Queued: 0   ⏱️  ETA: 2m 15s    │
│                                                             │
│ Currently Running:                                          │
│ • regression_438 (2m 30s) - P-value conversion test        │
│ • regression_347 (1m 45s) - Allele frequency flipping      │
│ • test_convert_neglogP (0m 30s) - Unit test                │
│                                                             │
│ Recent Completions:                                         │
│ ✅ regression_242 (1m 12s) - PASSED                        │
│ ✅ test_flip_effects (0m 58s) - PASSED                     │
└─────────────────────────────────────────────────────────────┘
```

#### 2.2 Job Manager (`tests/lib/job-manager.sh`)

**Core Functions:**
```bash
# Job queue management
init_job_queue()           # Initialize job queue and workers
add_job_to_queue()         # Add test to execution queue
start_next_job()           # Start next available job
monitor_running_jobs()     # Check job status and cleanup completed
wait_for_completion()      # Wait for all jobs with timeout
handle_job_failure()       # Retry logic and failure handling

# Process management
spawn_test_worker()        # Start individual test in background
cleanup_completed_jobs()   # Remove finished jobs from tracking
kill_all_jobs()           # Graceful shutdown of all running tests
```

**Job State Management:**
```bash
# Job states: QUEUED -> RUNNING -> COMPLETED/FAILED
declare -A job_states=()
declare -A job_pids=()
declare -A job_start_times=()
declare -A job_log_files=()
```

#### 2.3 Test Wrapper (`tests/lib/test-wrapper.sh`)

**Purpose:** Standardize test execution and logging
```bash
#!/usr/bin/env bash
# tests/lib/test-wrapper.sh

run_test_with_logging() {
    local test_name="$1"
    local test_script="$2"
    local log_dir="$3"
    
    # Create test-specific log file
    local test_log="${log_dir}/tests/${test_name}.log"
    mkdir -p "$(dirname "$test_log")"
    
    # Start time tracking
    local start_time=$(date +%s)
    echo "${test_name}-started" > "${log_dir}/status/${test_name}.status"
    
    # Execute test with full logging
    {
        echo "=== Test: ${test_name} ==="
        echo "=== Started: $(date -Iseconds) ==="
        echo "=== Script: ${test_script} ==="
        echo ""
        
        # Run the actual test
        if timeout 1800 "${test_script}"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo ""
            echo "=== Test completed successfully in ${duration}s ==="
            echo "${test_name}-succeeded" > "${log_dir}/status/${test_name}.status"
            echo "${test_name}-succeeded" >&2  # For orchestrator
            exit 0
        else
            local exit_code=$?
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo ""
            echo "=== Test failed with exit code ${exit_code} after ${duration}s ==="
            echo "${test_name}-failed" > "${log_dir}/status/${test_name}.status"
            echo "${test_name}-failed" >&2  # For orchestrator
            exit $exit_code
        fi
    } > "$test_log" 2>&1
}
```

### Phase 3: Enhanced Test Runners

#### 3.1 Enhanced run-e2e-tests.sh

**Key Changes:**
```bash
#!/usr/bin/env bash
# tests/run-e2e-tests.sh (Enhanced)

set -euo pipefail

# Source new libraries
test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${test_dir}/lib/utils.sh"
source "${test_dir}/lib/job-manager.sh"
source "${test_dir}/lib/progress-display.sh"

# Enhanced argument parsing
parse_arguments() {
    specific_test=""
    parallel_mode=false
    max_parallel_jobs=4  # Increased default
    show_progress=true
    verbose=false
    
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

# Main execution logic
main() {
    parse_arguments "$@"
    
    # Setup session logging
    local session_id=$(date +%Y%m%d-%H%M%S)
    local log_dir="${test_dir}/test_logs/session-${session_id}"
    mkdir -p "${log_dir}/tests" "${log_dir}/status"
    ln -sfn "session-${session_id}" "${test_dir}/test_logs/latest"
    
    if [[ -n "$specific_test" ]]; then
        run_specific_test "$specific_test" "$log_dir"
    else
        if [[ "$parallel_mode" == true ]]; then
            run_parallel_tests "$max_parallel_jobs" "$log_dir" "$show_progress"
        else
            run_sequential_tests "$log_dir"
        fi
    fi
}

# Parallel execution with progress tracking
run_parallel_tests() {
    local max_jobs=$1
    local log_dir=$2
    local show_progress=$3
    
    # Initialize progress display
    if [[ "$show_progress" == true ]] && [[ -t 1 ]]; then
        init_progress_display
    fi
    
    # Initialize job manager
    init_job_queue "$max_jobs" "$log_dir"
    
    # Queue all tests
    local test_files=("${test_dir}/e2e/"test_*.sh)
    for test_file in "${test_files[@]}"; do
        local test_name=$(basename "$test_file" .sh | sed 's/^test_//')
        add_job_to_queue "$test_name" "$test_file"
    done
    
    # Start execution with progress monitoring
    execute_job_queue_with_progress "$show_progress"
    
    # Generate summary
    generate_test_summary "$log_dir"
}
```

#### 3.2 Enhanced run-unit-tests.sh (NEW: Parallel Support)

**Key Addition:**
```bash
#!/usr/bin/env bash
# tests/run-unit-tests.sh (Enhanced with parallel support)

# Add parallel support similar to e2e tests
# Unit tests are typically faster, so higher parallelism is beneficial
DEFAULT_PARALLEL_JOBS=8  # Higher default for unit tests

# Same infrastructure as e2e tests but optimized for unit test characteristics
```

#### 3.3 Enhanced run-tests.sh (Coordinated Execution)

**Key Changes:**
```bash
#!/usr/bin/env bash
# tests/run-tests.sh (Enhanced coordination)

# Coordinate unit and e2e tests with shared progress display
run_all_tests_parallel() {
    local max_jobs=$1
    local log_dir=$2
    
    # Split jobs between unit and e2e tests
    local unit_jobs=$((max_jobs / 2))
    local e2e_jobs=$((max_jobs - unit_jobs))
    
    # Run both in parallel with shared progress tracking
    {
        echo "=== Starting Unit Tests (${unit_jobs} parallel) ==="
        "${test_dir}/run-unit-tests.sh" --parallel "$unit_jobs" --no-progress
    } &
    local unit_pid=$!
    
    {
        echo "=== Starting E2E Tests (${e2e_jobs} parallel) ==="
        "${test_dir}/run-e2e-tests.sh" --parallel "$e2e_jobs" --no-progress
    } &
    local e2e_pid=$!
    
    # Monitor both with unified progress display
    monitor_coordinated_execution "$unit_pid" "$e2e_pid" "$log_dir"
}
```

### Phase 4: Progress Display Implementation

#### 4.1 Real-time Progress Updates

**Core Functions:**
```bash
# tests/lib/progress-display.sh

# Terminal detection and setup
init_progress_display() {
    # Detect terminal capabilities
    if [[ ! -t 1 ]] || [[ "$TERM" == "dumb" ]]; then
        PROGRESS_MODE="simple"
    else
        PROGRESS_MODE="fancy"
        # Save terminal state
        tput smcup 2>/dev/null || true
        # Hide cursor
        tput civis 2>/dev/null || true
        # Setup cleanup trap
        trap cleanup_progress_display EXIT
    fi
}

# Real-time update function
update_progress_display() {
    local started=$1 running=$2 completed=$3 failed=$4 queued=$5
    local current_tests=("${@:6}")
    
    if [[ "$PROGRESS_MODE" == "simple" ]]; then
        # Simple mode for non-interactive terminals
        printf "\rProgress: %d started, %d running, %d completed, %d failed" \
               "$started" "$running" "$completed" "$failed"
    else
        # Fancy mode with full UI
        draw_fancy_progress_display "$started" "$running" "$completed" "$failed" "$queued" "${current_tests[@]}"
    fi
}

# Fancy progress display
draw_fancy_progress_display() {
    local started=$1 running=$2 completed=$3 failed=$4 queued=$5
    shift 5
    local current_tests=("$@")
    
    local total=$((started + running + completed + failed + queued))
    local percent=0
    if [[ $total -gt 0 ]]; then
        percent=$(( (completed + failed) * 100 / total ))
    fi
    
    # Clear screen and position cursor
    tput clear
    tput cup 0 0
    
    # Draw header
    printf "┌─────────────────────────────────────────────────────────────┐\n"
    printf "│ CleanSumStats Test Suite - Parallel Execution              │\n"
    printf "├─────────────────────────────────────────────────────────────┤\n"
    
    # Draw progress bar
    printf "│ Progress: "
    draw_progress_bar "$percent" 40
    printf " %3d%% (%d/%d)%*s│\n" "$percent" $((completed + failed)) "$total" $((40 - ${#percent} - ${#completed} - ${#failed} - ${#total} - 8)) ""
    
    printf "│%61s│\n" ""
    
    # Draw status counters
    printf "│ Status:  🟢 Started: %-3d  🔵 Running: %-3d  ✅ Passed: %-3d%6s│\n" \
           "$started" "$running" $((completed - failed)) ""
    printf "│          ❌ Failed: %-3d   ⏸️  Queued: %-3d   ⏱️  ETA: %s%*s│\n" \
           "$failed" "$queued" "$(calculate_eta)" 5 ""
    
    printf "│%61s│\n" ""
    
    # Draw currently running tests
    printf "│ Currently Running:%48s│\n" ""
    local i=0
    for test in "${current_tests[@]}"; do
        if [[ $i -lt 3 ]]; then  # Show max 3 running tests
            local duration=$(get_test_duration "$test")
            printf "│ • %-20s (%s)%*s│\n" "$test" "$duration" $((35 - ${#test} - ${#duration})) ""
        fi
        ((i++))
    done
    
    # Fill remaining lines
    for ((j=i; j<3; j++)); do
        printf "│%61s│\n" ""
    done
    
    printf "└─────────────────────────────────────────────────────────────┘\n"
}

# Progress bar drawing
draw_progress_bar() {
    local percent=$1
    local width=$2
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "]"
}
```

### Phase 5: Integration and Testing

#### 5.1 cleansumstats.sh Integration

**Minimal Changes Required:**
```bash
# CHANGE 1: Update test_logs path
testlogs_host="${project_dir}/tests/test_logs"  # Added /tests
testlogs_container="/cleansumstats/tests/test_logs"  # Added /tests

# CHANGE 2: Create directory in tests/
elif [ "${runtype}" == "test" ]; then
  mkdir -p tests/test_logs  # Changed path
  # ... rest unchanged

elif [ "${runtype}" == "utest" ]; then
  mkdir -p tests/test_logs  # Changed path
  # ... rest unchanged

elif [ "${runtype}" == "etest" ]; then
  mkdir -p tmp
  mkdir -p tests/test_logs  # Changed path
  # ... rest unchanged
```

#### 5.2 Backward Compatibility

**Ensure existing functionality works:**
- Single test execution: `./cleansumstats.sh etest regression_242`
- Sequential execution: `./cleansumstats.sh etest` (without --parallel)
- Existing log format compatibility
- Container mounting paths remain functional

### Phase 6: Advanced Features

#### 6.1 Enhanced CLI Options

```bash
# New options for cleansumstats.sh
-P, --parallel N        Max parallel jobs (default: 4 for e2e, 8 for unit)
--no-progress          Disable real-time progress display
--verbose              Increase verbosity
--timeout N            Test timeout in seconds (default: 1800)
--retry N              Retry failed tests N times (default: 0)
--fail-fast            Stop on first failure
--session-name NAME    Custom session name for logs
```

#### 6.2 Performance Monitoring

```bash
# Resource monitoring during test execution
monitor_system_resources() {
    while [[ $MONITORING_ACTIVE == true ]]; do
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
        
        echo "$(date -Iseconds),${cpu_usage},${mem_usage},${load_avg}" >> "${log_dir}/resources.csv"
        sleep 5
    done
}
```

#### 6.3 Test Summary and Reporting

```bash
# Generate comprehensive test summary
generate_test_summary() {
    local log_dir=$1
    local session_id=$(basename "$log_dir" | sed 's/session-//')
    
    # JSON summary for machine parsing
    cat > "${log_dir}/summary.json" <<EOF
{
  "session_id": "$session_id",
  "timestamp": "$(date -Iseconds)",
  "total_tests": $total_tests,
  "passed": $passed_tests,
  "failed": $failed_tests,
  "duration": $total_duration,
  "parallel_jobs": $max_parallel_jobs,
  "failed_tests": [$(printf '"%s",' "${failed_test_names[@]}" | sed 's/,$//')],
  "performance": {
    "avg_test_duration": $avg_duration,
    "max_parallel_achieved": $max_parallel_achieved,
    "cpu_usage_avg": $avg_cpu_usage,
    "memory_usage_peak": $peak_memory_usage
  }
}
EOF

    # Human-readable summary
    cat > "${log_dir}/summary.txt" <<EOF
CleanSumStats Test Execution Summary
====================================
Session: $session_id
Date: $(date)
Duration: $(format_duration $total_duration)

Results:
  Total Tests: $total_tests
  Passed: $passed_tests
  Failed: $failed_tests
  Success Rate: $(( passed_tests * 100 / total_tests ))%

Performance:
  Parallel Jobs: $max_parallel_jobs
  Average Test Duration: $(format_duration $avg_duration)
  Total CPU Time Saved: $(format_duration $time_saved)

$(if [[ $failed_tests -gt 0 ]]; then
    echo "Failed Tests:"
    for test in "${failed_test_names[@]}"; do
        echo "  - $test"
    done
fi)

Logs available in: $log_dir
EOF
}
```

## 🚀 Implementation Timeline

### Week 1: Core Infrastructure
1. **Day 1-2:** Create `tests/lib/` structure and basic utilities
2. **Day 3-4:** Implement job manager and progress display
3. **Day 5:** Update cleansumstats.sh with minimal changes

### Week 2: Enhanced Test Runners
1. **Day 1-2:** Enhance run-e2e-tests.sh with new infrastructure
2. **Day 3:** Add parallel support to run-unit-tests.sh
3. **Day 4-5:** Update run-tests.sh for coordinated execution

### Week 3: Testing and Polish
1. **Day 1-2:** Comprehensive testing of new system
2. **Day 3:** Performance optimization and tuning
3. **Day 4-5:** Documentation and final integration

## 🧪 Testing Strategy

### Validation Tests
1. **Functionality:** All existing tests pass with new system
2. **Performance:** Parallel execution shows expected speedup
3. **Robustness:** Handle failures, interruptions, resource limits
4. **Compatibility:** Works with existing cleansumstats.sh flows
5. **UI/UX:** Progress display works across different terminals

### Test Scenarios
```bash
# Test different execution modes
./cleansumstats.sh etest                           # All tests, default parallel
./cleansumstats.sh etest -P 8                      # High parallelism
./cleansumstats.sh etest regression_242            # Single test
./cleansumstats.sh etest --no-progress             # No progress display
./cleansumstats.sh test -P 6                       # All tests (unit + e2e)
./cleansumstats.sh utest -P 12                     # Unit tests only, high parallel
```

## 📈 Expected Benefits

### Performance Improvements
- **E2E Tests:** ~4x speedup with 4 parallel jobs (21 tests)
- **Unit Tests:** ~8x speedup with 8 parallel jobs (25+ tests)
- **Combined:** ~6x overall speedup for full test suite

### User Experience
- **Real-time feedback** with progress tracking
- **Clear status** of running, completed, and failed tests
- **Detailed logging** for debugging failures
- **Professional appearance** with structured output

### Maintainability
- **Modular design** with reusable components
- **Minimal changes** to existing infrastructure
- **Backward compatibility** preserved
- **Easy to extend** for future enhancements

This implementation plan provides a robust, user-friendly parallel test execution system while maintaining compatibility with the existing CleanSumStats infrastructure and requiring minimal changes to the core `cleansumstats.sh` script. 
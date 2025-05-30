#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source simple utils for session management
source "${test_dir}/lib/utils.sh"

# Parse arguments
specific_test=""

while [[ $# -gt 0 ]]; do
  case $1 in
    *)
      if [ -z "$specific_test" ]; then
        specific_test="$1"
      fi
      shift
      ;;
  esac
done

# Create session directory for organized logging
session_id=$(date +%Y%m%d-%H%M%S)
session_dir="${test_dir}/test_logs/session-${session_id}"
mkdir -p "${session_dir}"

log_info "Starting e2e test session: $session_id"
log_info "Session logs will be saved to: $session_dir"

# Check if a specific test is provided
if [ -n "$specific_test" ]; then
  test_file="${test_dir}/e2e/test_${specific_test}.sh"
  
  if [ -f "${test_file}" ]; then
    echo "Running specific test: ${specific_test}"
    log_file="${session_dir}/${specific_test}.log"
    
    # Run test and capture output
    echo "=== Test: $specific_test ===" > "$log_file"
    echo "Started: $(date)" >> "$log_file"
    echo "" >> "$log_file"
    
    if "${test_file}" >> "$log_file" 2>&1; then
      echo "Status: PASSED" >> "$log_file"
      echo "Completed: $(date)" >> "$log_file"
      echo "=== $specific_test PASSED ==="
    else
      echo "Status: FAILED" >> "$log_file"
      echo "Completed: $(date)" >> "$log_file"
      echo "=== $specific_test FAILED ==="
      echo "Check log: $log_file"
      exit 1
    fi
  else
    echo "Error: Test file ${test_file} not found"
    echo "Available tests:"
    ls "${test_dir}/e2e/"test_*.sh | sed 's/.*test_//' | sed 's/\.sh$//' | sort
    exit 1
  fi
else
  # Run all tests sequentially with session logging
  echo "Running all e2e tests sequentially..."
  echo "Session: $session_id"
  echo "Logs: $session_dir"
  echo ""
  
  failed_tests=()
  passed_tests=()
  start_time=$(get_timestamp)
  
  # Create session summary file
  summary_file="${session_dir}/session-summary.log"
  echo "=== E2E Test Session Summary ===" > "$summary_file"
  echo "Session ID: $session_id" >> "$summary_file"
  echo "Started: $(date)" >> "$summary_file"
  echo "Command: $0 $*" >> "$summary_file"
  echo "" >> "$summary_file"
  
  for test_file in "${test_dir}/e2e/"test_*.sh
  do
    test_name=$(basename "$test_file" .sh | sed 's/^test_//')
    log_file="${session_dir}/${test_name}.log"
    
    echo "=== Running $test_name ==="
    echo "Running: $test_name" >> "$summary_file"
    
    # Create individual test log
    echo "=== Test: $test_name ===" > "$log_file"
    echo "Started: $(date)" >> "$log_file"
    echo "Log file: $log_file" >> "$log_file"
    echo "" >> "$log_file"
    
    if "${test_file}" >> "$log_file" 2>&1; then
      echo "Status: PASSED" >> "$log_file"
      echo "Completed: $(date)" >> "$log_file"
      echo "=== $test_name PASSED ==="
      echo "  Status: PASSED" >> "$summary_file"
      passed_tests+=("$test_name")
    else
      echo "Status: FAILED" >> "$log_file"
      echo "Completed: $(date)" >> "$log_file"
      echo "=== $test_name FAILED ==="
      echo "  Status: FAILED" >> "$summary_file"
      failed_tests+=("$test_name")
    fi
    echo ""
  done
  
  end_time=$(get_timestamp)
  total_duration=$((end_time - start_time))
  
  # Complete session summary
  echo "" >> "$summary_file"
  echo "=== Final Results ===" >> "$summary_file"
  echo "Completed: $(date)" >> "$summary_file"
  echo "Duration: $(format_duration $total_duration)" >> "$summary_file"
  echo "Total: $((${#passed_tests[@]} + ${#failed_tests[@]}))" >> "$summary_file"
  echo "Passed: ${#passed_tests[@]}" >> "$summary_file"
  echo "Failed: ${#failed_tests[@]}" >> "$summary_file"
  echo "" >> "$summary_file"
  
  if [ ${#failed_tests[@]} -gt 0 ]; then
    echo "Failed tests:" >> "$summary_file"
    for test in "${failed_tests[@]}"; do
      echo "  - $test" >> "$summary_file"
    done
  fi
  
  if [ ${#passed_tests[@]} -gt 0 ]; then
    echo "" >> "$summary_file"
    echo "Passed tests:" >> "$summary_file"
    for test in "${passed_tests[@]}"; do
      echo "  - $test" >> "$summary_file"
    done
  fi
  
  # Report results to console
  echo "=================================="
  echo "E2E Test Results (Session: $session_id):"
  echo "  Total: $((${#passed_tests[@]} + ${#failed_tests[@]}))"
  echo "  Passed: ${#passed_tests[@]}"
  echo "  Failed: ${#failed_tests[@]}"
  echo "  Duration: $(format_duration $total_duration)"
  echo "  Logs: $session_dir"
  
  if [ ${#failed_tests[@]} -gt 0 ]; then
    echo ""
    echo "Failed tests:"
    for test in "${failed_tests[@]}"; do
      echo "  - $test (log: ${session_dir}/${test}.log)"
    done
    echo ""
    echo "Session summary: $summary_file"
    exit 1
  else
    echo ""
    echo "All e2e tests passed!"
    echo "Session summary: $summary_file"
    exit 0
  fi
fi

# run only one regression test
#${test_dir}/e2e/test_regression_missing_variants.sh



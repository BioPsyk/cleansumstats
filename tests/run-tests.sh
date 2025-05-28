#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Parse arguments
specific_test=""
parallel_mode=false
max_parallel_jobs=2

for arg in "$@"; do
  case $arg in
    --parallel)
      parallel_mode=true
      # Check if next argument is a number
      shift
      if [[ $# -gt 0 && $1 =~ ^[0-9]+$ ]]; then
        max_parallel_jobs=$1
        shift
      fi
      break
      ;;
    *)
      if [ -z "$specific_test" ]; then
        specific_test="$arg"
      fi
      ;;
  esac
  shift
done

# Check if a specific test is provided
if [ -n "$specific_test" ]; then
  # Check if it's a unit test or e2e test
  if [ -f "${test_dir}/unit/test_${specific_test}.sh" ]; then
    echo "Running specific unit test: ${specific_test}"
    time "${test_dir}/run-unit-tests.sh" "${specific_test}"
  elif [ -f "${test_dir}/e2e/test_${specific_test}.sh" ]; then
    echo "Running specific e2e test: ${specific_test}"
    if [ "$parallel_mode" = true ]; then
      time "${test_dir}/run-e2e-tests.sh" "${specific_test}" --parallel "${max_parallel_jobs}"
    else
      time "${test_dir}/run-e2e-tests.sh" "${specific_test}"
    fi
  else
    echo "Error: Test '${specific_test}' not found in unit or e2e tests"
    echo "Available unit tests:"
    ls "${test_dir}/unit/"test_*.sh | sed 's/.*test_//' | sed 's/\.sh$//' | sort
    echo "Available e2e tests:"
    ls "${test_dir}/e2e/"test_*.sh | sed 's/.*test_//' | sed 's/\.sh$//' | sort
    exit 1
  fi
else
  # Run all tests
  if [ "$parallel_mode" = true ]; then
    echo "Running tests with parallel e2e execution (max ${max_parallel_jobs} jobs)..."
    (
      echo "=== Starting unit tests ==="
      time "${test_dir}/run-unit-tests.sh"
      echo "=== Unit tests completed ==="
    ) &
    unit_pid=$!
    
    (
      echo "=== Starting e2e tests ==="
      time "${test_dir}/run-e2e-tests.sh" --parallel "${max_parallel_jobs}"
      echo "=== E2E tests completed ==="
    ) &
    e2e_pid=$!
    
    # Wait for both test suites
    unit_result=0
    e2e_result=0
    
    if ! wait $unit_pid; then
      unit_result=1
      echo "Unit tests failed"
    fi
    
    if ! wait $e2e_pid; then
      e2e_result=1
      echo "E2E tests failed"
    fi
    
    if [ $unit_result -ne 0 ] || [ $e2e_result -ne 0 ]; then
      exit 1
    fi
    
    echo "All tests completed successfully!"
  else
    # Run tests sequentially
    time "${test_dir}/run-unit-tests.sh"
    time "${test_dir}/run-e2e-tests.sh"
  fi
fi

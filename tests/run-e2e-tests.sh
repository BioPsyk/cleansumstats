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
    echo "Running e2e tests in parallel (max ${max_parallel_jobs} jobs)..."
    pids=()
    test_files=("${test_dir}/e2e/"test_*.sh)
    
    for test_file in "${test_files[@]}"; do
      test_name=$(basename "$test_file" .sh)
      
      # Wait if we've reached the maximum number of parallel jobs
      while [ ${#pids[@]} -ge $max_parallel_jobs ]; do
        # Check for completed jobs
        new_pids=()
        for pid in "${pids[@]}"; do
          if kill -0 "$pid" 2>/dev/null; then
            new_pids+=("$pid")
          fi
        done
        pids=("${new_pids[@]}")
        
        # Small delay to avoid busy waiting
        if [ ${#pids[@]} -ge $max_parallel_jobs ]; then
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
    else
      echo "Failed tests: ${failed_tests[*]}"
      exit 1
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



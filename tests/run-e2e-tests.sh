#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if a specific test name was provided as the first argument
if [ $# -eq 1 ]; then
  specific_test="$1"
  test_file="${test_dir}/e2e/test_${specific_test}.sh"
  
  if [ -f "${test_file}" ]; then
    echo "Running specific test: ${specific_test}"
    "${test_file}"
  else
    echo "Error: Test file not found: ${test_file}"
    echo "Available tests:"
    for f in "${test_dir}/e2e/"test_*.sh; do
      basename "${f}" .sh | sed 's/^test_/  - /'
    done
    exit 1
  fi
else
  # Run all tests
  for test_file in "${test_dir}/e2e/"test_*.sh
  do
    "${test_file}"
  done
fi

# run only one regression test
#${test_dir}/e2e/test_regression_missing_variants.sh



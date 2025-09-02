#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PROJECT_DIR=$(dirname "${test_dir}")
export PATH="${PATH}:${PROJECT_DIR}/bin"
export ch_regexp_lexicon="${PROJECT_DIR}/assets/map_regexp_and_adhocfunction.txt"

tmp_dir=$(mktemp -d)

function cleanup()
{
  cd "${test_dir}"
  rm -rf "${tmp_dir}"
}

trap cleanup EXIT

echo "==================================================================="
echo "| Running unit tests in: ${tmp_dir}"
echo "==================================================================="
cd "${tmp_dir}"

# Parse arguments - only look for specific test name
specific_test=""

for arg in "$@"; do
  if [ -z "$specific_test" ]; then
    specific_test="$arg"
  fi
done

# Check if a specific test is provided
if [ -n "$specific_test" ]; then
  test_file="${test_dir}/unit/test_${specific_test}.sh"
  
  if [ -f "${test_file}" ]; then
    echo "Running specific unit test: ${specific_test}"
    "${test_file}"
  else
    echo "Error: Unit test file ${test_file} not found"
    echo "Available unit tests:"
    ls "${test_dir}/unit/"test_*.sh | sed 's/.*test_//' | sed 's/\.sh$//' | sort
    exit 1
  fi
else
  # Run all unit tests sequentially
  # #Test only one case (for dev purposes)
  #"${test_dir}/unit/test_dbsnp_reference_filter_and_convert.sh"
  #exit 0

  for test_file in "${test_dir}/unit/"test_*.sh
  do
    "${test_file}"
  done
fi

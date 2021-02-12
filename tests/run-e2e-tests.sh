#!/usr/bin/env bash

set -euo pipefail

tests_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_dir=$(dirname "${tests_dir}")
tmp_dir="${project_dir}/tmp"

rm -rf "${tmp_dir}/"*

echo "==================================================================="
echo "| Running e2e tests"
echo "==================================================================="

for test_file in "${tests_dir}/e2e/"test_*.sh
do
  "${test_file}"
done

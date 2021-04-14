#!/usr/bin/env bash

set -euo pipefail

test_script="metadata_legacy_to_yaml"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

mkdir "${initial_dir}"
cd "${initial_dir}"

#=================================================================================
# Helpers
#=================================================================================

function _setup {
  mkdir "${1}"
  cd "${1}"
  curr_case="${1}"
}

function _run_script {
  "${test_script}.py" "$1"

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

for example_data in "${PROJECT_DIR}/tests/example_data/"sumstat_*
do
  name=$(basename "${example_data}")
  _setup "${name}"

  cp "${example_data}" "./${name}" -R

  _run_script "$(pwd)/${name}/${name}_raw_meta.txt"
done

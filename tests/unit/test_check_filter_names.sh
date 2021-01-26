#!/usr/bin/env bash

set -euo pipefail

test_script="check_filter_names"
initial_dir=$(pwd)"/${test_script}"
allowed_filters="${PROJECT_DIR}/assets/allowed_names_afterLiftoverFilter.txt"
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
  script_result=$("${test_script}.sh" "${1}" "${allowed_filters}" ./result.log; echo $?)
  grep_result=$(grep "fail" ./result.log; echo $?)

  if [[ "${script_result}" != 0 || "${grep_result}" == 0 ]]; then
    echo "- [FAIL] ${curr_case}: Found failure in log-file:"
    cat ./result.log
    exit 2
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using no filters at all

_setup "no_filters"
_run_script ""

#---------------------------------------------------------------------------------
# Using one allowed filters

_setup "one_allowed_filter"
_run_script "duplicated_chrpos_refalt_in_GRCh38"

#---------------------------------------------------------------------------------
# Using multiple allowed filters

_setup "multiple_allowed_filters"
_run_script "duplicated_chrpos_refalt_in_GRCh38,multiple_rsids_in_dbsnp"

#---------------------------------------------------------------------------------
# Using invalid filter

_setup "invalid_filter"
_run_script "test"

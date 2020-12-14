#!/usr/bin/env bash

set -euo pipefail

test_script="assign_folder_id"
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
  result=$("${test_script}.sh" "./")

  if [[ "${result}" != "${1}" ]]; then
    echo "- [FAIL] ${curr_case}: Expected ${1}, but got ${result}"
    exit 1
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using an empty library directory

_setup "no_directories"

_run_script "sumstat_1"

#---------------------------------------------------------------------------------
# Using a bunch of incorretly named directories

_setup "incorrect_names"

mkdir "gwas_1"
mkdir "sumstats_321"
mkdir "sstats_32"
mkdir "sumstat32"

_run_script "sumstat_1"

#---------------------------------------------------------------------------------
# Using an inconcistent sequence of id numbers

_setup "inconcistent_sequence"

mkdir "sumstat_4"
mkdir "sumstat_99"
mkdir "sumstat_103"

_run_script "sumstat_104"

#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
tmp_dir=$(dirname "${tests_dir}")/tmp/e2e
reports_dir=$(dirname "${tests_dir}")/tmp/reports
schemas_dir=$(dirname "${tests_dir}")/assets/schemas
log_dir="${tests_dir}/test_logs"

# Create log directory if it doesn't exist
mkdir -p "${log_dir}"

echo "test-cases-started"

# Redirect all output to log file
exec > "${log_dir}/test-cases.log" 2>&1

rm -rf "${reports_dir}"
mkdir "${reports_dir}"

rm -rf "${tmp_dir}"
mkdir "${tmp_dir}"

echo "==================================================================="
echo "| Running e2e tests in: ${tmp_dir}"
echo "==================================================================="

cd "${tmp_dir}"

for case_path in "${tests_dir}/e2e/cases/"*
#for case_path in "${test_dir}/e2e/cases/grch38-all-cols-multiline-chrpos-in-markername-column"
do
  if [[ -d "${case_path}" ]]
  then
    case_name=$(basename "${case_path}")
    case_dir="${tmp_dir}/${case_name}"

    echo ">> Test ${case_name}"

    cp "${case_path}" "${case_dir}" -R
    mkdir "${case_dir}/lib"
    mkdir "${case_dir}/out"

    cd "${case_dir}"

    gzip "./sumstats.txt"

    time nextflow -q run -offline \
         -c "/cleansumstats/conf/test.config" \
         -with-report "${reports_dir}/${case_name}_report.html" \
         -with-timeline "${reports_dir}/${case_name}_timeline.html" \
         -work-dir "${case_dir}" \
         "/cleansumstats" \
         --dev true \
         --input '*.yaml' \
         --outdir "./out" \
         --libdirdbsnp "${tests_dir}/e2e/data/dbsnp" \
         --libdir1kaf "${tests_dir}/e2e/data/1kaf"

    if [[ $? != 0 ]]
    then
      cat .nextflow.log
      echo "test-cases-failed" > /dev/stderr
      exit 1
    fi

    echo "-- Pipeline done, validating results"

    for f in ./out/cleaned_metadata.yaml
    do
      "${tests_dir}/validators/validate-cleaned-metadata.py" \
        "${schemas_dir}/cleaned-metadata.yaml" "${f}"
    done

    for f in ./out/*.gz
    do
      gzip --decompress "${f}"
      "${tests_dir}/validators/validate-cleaned-sumstats.py" \
        "${schemas_dir}/cleaned-sumstats.yaml" "${f%.gz}"
    done

    echo "-- All checks OK"

    cd "${tmp_dir}"
  fi
done

echo "test-cases-succeeded" > /dev/stderr

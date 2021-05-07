#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
test_dir=$(dirname "${e2e_dir}")
tmp_dir=$(dirname "${test_dir}")/tmp/e2e
reports_dir=$(dirname "${test_dir}")/tmp/reports
schemas_dir=$(dirname "${test_dir}")/assets/schemas

rm -rf "${reports_dir}"
mkdir "${reports_dir}"

rm -rf "${tmp_dir}"
mkdir "${tmp_dir}"

echo "==================================================================="
echo "| Running e2e tests in: ${tmp_dir}"
echo "==================================================================="

cd "${tmp_dir}"

#for case_path in "${test_dir}/e2e/cases/"*
for case_path in "${test_dir}/e2e/cases/grch38-all-cols-multiline-chrpos-in-markername-column"
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
         -with-report "${reports_dir}/${case_name}_report.html" \
         -with-timeline "${reports_dir}/${case_name}_timeline.html" \
         -work-dir "${case_dir}" \
         "/cleansumstats" \
         --dev true \
         --input '*.yaml' \
         --outdir "./out" \
         --libdirdbsnp "${test_dir}/e2e/data/dbsnp" \
         --libdir1kaf "${test_dir}/e2e/data/1kaf"

    if [[ $? != 0 ]]
    then
      cat .nextflow.log
      exit 1
    fi

    echo "-- Pipeline done, validating results"

    for f in ./out/**/cleaned_metadata.yaml
    do
      "${test_dir}/validators/validate-cleaned-metadata.py" \
        "${schemas_dir}/cleaned-metadata.yaml" "${f}"
    done

    for f in ./out/**/*.gz
    do
      gzip --decompress "${f}"
      "${test_dir}/validators/validate-cleaned-sumstats.py" \
        "${schemas_dir}/cleaned-sumstats.yaml" "${f%.gz}"
    done

    echo "-- All checks OK"

    cd "${tmp_dir}"
  fi
done

#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
tmp_dir="${project_dir}/tmp/e2e"
reports_dir="${project_dir}/tmp/reports"
schemas_dir="${project_dir}/assets/schemas"

mkdir "${tmp_dir}"
cd "${tmp_dir}"

for case_path in "${tests_dir}/e2e/cases/"*
do
  if [[ -d "${case_path}" ]]
  then
    case_name=$(basename "${case_path}")
    case_dir="${tmp_dir}/${case_name}"

    echo ">> Test case '${case_name}'"

    cp "${case_path}" "${case_dir}" -R
    mkdir -p "${case_dir}/lib"
    mkdir -p "${case_dir}/out"

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
         --libdir "./lib" \
         --libdirdbsnp "${tests_dir}/e2e/data/dbsnp" \
         --libdir1kaf "${tests_dir}/e2e/data/1kaf"

    if [[ $? != 0 ]]
    then
      cat .nextflow.log
      exit 1
    fi

    echo "-- Pipeline done, validating results"

    for f in ./out/**/cleaned_metadata.yaml
    do
      "${tests_dir}/validators/validate-cleaned-metadata.py" \
        "${schemas_dir}/cleaned-metadata.yaml" "${f}"
    done

    for f in ./out/**/*.gz
    do
      gzip --decompress "${f}"
      "${tests_dir}/validators/validate-cleaned-sumstats.py" \
        "${schemas_dir}/cleaned-sumstats.yaml" "${f%.gz}"
    done

    echo "-- All checks OK"

    cd "${tmp_dir}"
  fi
done

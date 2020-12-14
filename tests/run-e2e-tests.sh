#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmp_dir=$(dirname "${test_dir}")/tmp/e2e

rm -rf "${tmp_dir}"
mkdir "${tmp_dir}"

echo ">> Running e2e tests in: ${tmp_dir}"
cd "${tmp_dir}"

for case_path in "${test_dir}/e2e/"*
do
  if [[ -d "${case_path}" ]]
  then
    case_name=$(basename "${case_path}")
    case_dir="${tmp_dir}/${case_name}"

    echo ">> Starting test case ${case_name}"

    cp "${case_path}" "${case_dir}" -R
    mkdir "${case_dir}/lib"
    mkdir "${case_dir}/out"

    cd "${case_dir}"

    gzip "./sumstats.txt"

    nextflow run -ansi-log -offline -work-dir "${case_dir}" \
             "/cleansumstats" \
             --dev false \
             --input "./metadata.txt" \
             --outdir "./out" \
             --libdir "./lib" \
             --libdirdbsnp "./dbsnp" \
             --libdir1kaf "./1kaf"

    cd "${tmp_dir}"
  fi
done

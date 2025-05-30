#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
case_name="grch38-all-cols"
work_dir="${project_dir}/tmp/regression-134"
log_dir="${tests_dir}/test_logs"

# Create log directory if it doesn't exist
mkdir -p "${log_dir}"

echo "regression-134-started"

# Redirect all output to log file
exec > "${log_dir}/regression-134.log" 2>&1

rm -rf "${work_dir}"
mkdir "${work_dir}"

cd "${work_dir}"

cp "${e2e_dir}/cases/${case_name}" "${work_dir}/${case_name}" -R

gzip "${work_dir}/${case_name}/sumstats.txt"

time nextflow -q run -offline \
         -c "/cleansumstats/conf/test.config" \
     -work-dir "${work_dir}" \
     "/cleansumstats" \
     --dev true \
     --input "${work_dir}/${case_name}/*.yaml" \
     --outdir "./out" \
     --libdirdbsnp "${e2e_dir}/data/dbsnp" \
     --libdir1kaf "${e2e_dir}/data/1kaf"

if [[ $? != 0 ]]
then
  cat .nextflow.log
  echo "regression-134-failed" > /dev/stderr
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

echo "regression-134-succeeded" > /dev/stderr

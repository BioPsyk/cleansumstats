#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
case_name="grch38-all-cols"
work_dir="${project_dir}/tmp/regression-134"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #134"

cd "${work_dir}"

cp "${e2e_dir}/cases/${case_name}" "${work_dir}/${case_name}" -R

gzip "${work_dir}/${case_name}/sumstats.txt"

time nextflow -q run -offline \
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

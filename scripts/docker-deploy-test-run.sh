#!/usr/bin/env bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_dir=$(dirname "${script_dir}")

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

source "./scripts/init-containerization.sh"

echo ">> Running deploy container"

test_dir="tmp/deploy-container"

rm -rf "${test_dir}"
mkdir "${test_dir}"

cp "tests/e2e/cases/grch35-all-cols" "${test_dir}/in" -R
cp "tests/e2e/data" "${test_dir}/data" -R
mkdir "${test_dir}/out"

cd "${test_dir}/in"

gzip "./sumstats.txt"

docker run \
       -v "${project_dir}/tmp:/cleansumstats/tmp" \
       -v "${project_dir}/main.nf:/cleansumstats/main.nf" \
       "${deploy_image_tag}" \
       nextflow run /cleansumstats \
       --input '/cleansumstats/tmp/deploy-container/in/*.yaml' \
       --outdir "/cleansumstats/tmp/deploy-container/out" \
       --libdirdbsnp "/cleansumstats/tmp/deploy-container/data/dbsnp" \
       --libdir1kaf "/cleansumstats/tmp/deploy-container/data/1kaf"

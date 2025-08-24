#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
test_dir=$(dirname "${e2e_dir}")
tmp_dir=$(dirname "${test_dir}")/tmp/e2e_maponly
reports_dir=$(dirname "${test_dir}")/tmp/reports

rm -rf "${reports_dir}"
mkdir -p "${reports_dir}"

rm -rf "${tmp_dir}"
mkdir -p "${tmp_dir}"

echo "==================================================================="
echo "| Running maponly e2e test in: ${tmp_dir}"
echo "==================================================================="

cd "${tmp_dir}"

case_name="maponly_basics"
case_path="${e2e_dir}/maponly_basics"
case_dir="${tmp_dir}/${case_name}"

echo ">> Test ${case_name} - Testing map-only workflow"

cp -R "${case_path}" "${case_dir}"
mkdir "${case_dir}/lib"
mkdir "${case_dir}/out"

cd "${case_dir}"

gzip "./sumstats.txt"

echo "-- Running map-only workflow with Nextflow"

# Check if we're running inside Docker container
if [[ -f /.dockerenv ]] || [[ -n "${SINGULARITY_CONTAINER:-}" ]]; then
    # We're inside a container, run nextflow directly
    time nextflow -q run -offline \
         -with-report "${reports_dir}/${case_name}_report.html" \
         -with-timeline "${reports_dir}/${case_name}_timeline.html" \
         -work-dir "${case_dir}" \
         "/cleansumstats/main.nf" \
         --dev true \
         --mapping_only true \
         --input '*.yaml' \
         --outdir "./out" \
         --libdirdbsnp "${test_dir}/e2e/data/dbsnp" \
         --libdir1kaf "${test_dir}/e2e/data/1kaf"
else
    # We're outside container, need to use the wrapper script
    echo "ERROR: This test must be run inside a Docker container"
    echo "Please use: ./cleansumstats.sh test -e --image docker"
    exit 1
fi

if [[ $? != 0 ]]
then
  echo "-- Pipeline failed, showing logs:"
  cat .nextflow.log
  exit 1
fi

echo "-- Pipeline completed successfully"

echo "-- Checking output files exist"

if [[ ! -f "./out/GRCh38_mapped.gz" ]]; then
    echo "ERROR: GRCh38_mapped.gz not found"
    exit 1
fi

if [[ ! -f "./out/GRCh37_mapped.gz" ]]; then
    echo "ERROR: GRCh37_mapped.gz not found"
    exit 1
fi

if [[ ! -f "./out/unmapped.gz" ]]; then
    echo "ERROR: unmapped.gz not found"
    exit 1
fi

echo "-- Decompressing and checking mapped output"

gzip -d "./out/GRCh38_mapped.gz"
gzip -d "./out/GRCh37_mapped.gz"
gzip -d "./out/unmapped.gz"

echo "-- Checking GRCh38 mapped variants"
grch38_count=$(wc -l < "./out/GRCh38_mapped")
echo "   GRCh38 mapped variants: $((grch38_count - 1)) (excluding header)"

echo "-- Checking GRCh37 mapped variants"
grch37_count=$(wc -l < "./out/GRCh37_mapped")
echo "   GRCh37 mapped variants: $((grch37_count - 1)) (excluding header)"

echo "-- Checking unmapped variants"
unmapped_count=$(wc -l < "./out/unmapped")
echo "   Unmapped variants: $((unmapped_count - 1)) (excluding header)"

echo "-- Verifying that unmapped variants are in unmapped file"
# Since our test dbSNP reference only has rs1000, all our test variants should be unmapped
if ! grep -q "rs3094315" "./out/unmapped"; then
    echo "ERROR: Expected rsID rs3094315 not found in unmapped output"
    exit 1
fi

if ! grep -q "UNKNOWN_VAR1" "./out/unmapped"; then
    echo "ERROR: Expected unknown variant UNKNOWN_VAR1 not found in unmapped output"
    exit 1
fi

if ! grep -q "UNKNOWN_VAR2" "./out/unmapped"; then
    echo "ERROR: Expected unknown variant UNKNOWN_VAR2 not found in unmapped output"
    exit 1
fi

echo "-- Verifying unmapped count matches expected"
# All 10 variants should be unmapped since none match rs1000
if [ "$((unmapped_count - 1))" -ne 10 ]; then
    echo "ERROR: Expected 10 unmapped variants, got $((unmapped_count - 1))"
    exit 1
fi

echo "-- Checking column structure of mapped files"
grch38_header=$(head -1 "./out/GRCh38_mapped")

# The mapped file has the dbSNP mapping output structure
# It should have columns like: row_index, CHRPOS, RSID, A1, A2
if [[ ! "${grch38_header}" == *"RSID"* ]]; then
    echo "ERROR: GRCh38 mapped file missing RSID column"
    echo "Header: ${grch38_header}"
    exit 1
fi

if [[ ! "${grch38_header}" == *"CHRPOS"* ]]; then
    echo "ERROR: GRCh38 mapped file missing CHRPOS column"
    echo "Header: ${grch38_header}"
    exit 1
fi

echo "-- All checks passed successfully!"
echo "==================================================================="
echo "| Map-only workflow test completed successfully"
echo "==================================================================="
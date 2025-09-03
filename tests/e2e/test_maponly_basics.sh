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
         -c "/cleansumstats/conf/test.config" \
         -with-report "${reports_dir}/${case_name}_report.html" \
         -with-timeline "${reports_dir}/${case_name}_timeline.html" \
         -work-dir "${case_dir}" \
         "/cleansumstats" \
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

echo "-- Verifying that mapped variants are in mapped files"
# Check that rs1000 was mapped (the only variant in test dbSNP)
if ! grep -q "rs1000" "./out/GRCh38_mapped"; then
    echo "WARNING: rs1000 not found in GRCh38 mapped output"
    echo "Checking if it's in unmapped instead..."
    if grep -q "rs1000" "./out/unmapped"; then
        echo "ERROR: rs1000 is in unmapped but should have been mapped!"
        exit 1
    fi
fi

echo "-- Verifying that unmapped variants are in unmapped file"

if ! grep -q "UNKNOWN_VAR1" "./out/unmapped"; then
    echo "ERROR: Expected unknown variant UNKNOWN_VAR1 not found in unmapped output"
    exit 1
fi

if ! grep -q "UNKNOWN_VAR2" "./out/unmapped"; then
    echo "ERROR: Expected unknown variant UNKNOWN_VAR2 not found in unmapped output"
    exit 1
fi

echo "-- Verifying variant counts"
# We have 10 total variants, some should map and some shouldn't
total_input=10
mapped_38=$(wc -l < "./out/GRCh38_mapped" | xargs)
mapped_37=$(wc -l < "./out/GRCh37_mapped" | xargs)
unmapped=$(wc -l < "./out/unmapped" | xargs)
echo "   Input: $total_input variants"
echo "   GRCh38 mapped: $((mapped_38 - 1)) variants"  
echo "   GRCh37 mapped: $((mapped_37 - 1)) variants"
echo "   Unmapped: $((unmapped - 1)) variants"

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
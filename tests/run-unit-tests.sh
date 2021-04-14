#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PROJECT_DIR=$(dirname "${test_dir}")
export PATH="${PATH}:${PROJECT_DIR}/bin"

tmp_dir=$(mktemp -d)

function cleanup()
{
  cd "${test_dir}"
  rm -rf "${tmp_dir}"
}

trap cleanup EXIT

echo "==================================================================="
echo "| Running unit tests in: ${tmp_dir}"
echo "==================================================================="
cd "${tmp_dir}"

"${test_dir}/unit/test_metadata_legacy_to_yaml.sh"

exit 0

for test_file in "${test_dir}/unit/"test_*.sh
do
  "${test_file}"
done

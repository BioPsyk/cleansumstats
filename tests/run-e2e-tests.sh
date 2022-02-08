#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for test_file in "${test_dir}/e2e/"test_*.sh
do
  "${test_file}"
done

## run only one regression test
#${test_dir}/e2e/test_regression_282.sh


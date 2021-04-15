#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

time "${test_dir}/run-unit-tests.sh"
exit 0
time "${test_dir}/run-e2e-tests.sh"

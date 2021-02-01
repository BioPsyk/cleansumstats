#!/usr/bin/env bash

set -euo pipefail

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

time "${test_dir}/run-unit-tests.sh"
time "${test_dir}/run-e2e-tests.sh"

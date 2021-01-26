#!/usr/bin/env bash

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${test_dir}/run-unit-tests.sh"
"${test_dir}/run-e2e-tests.sh"

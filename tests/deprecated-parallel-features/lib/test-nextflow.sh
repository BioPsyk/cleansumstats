#!/usr/bin/env bash

# Test wrapper for Nextflow that automatically applies test-specific configuration
# This ensures all tests use minimal resources to prevent resource exhaustion
# during parallel test execution.

set -euo pipefail

# Get the directory where this script is located
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${script_dir}")
project_dir=$(dirname "${tests_dir}")

# Add test configuration to Nextflow command
exec nextflow "$@" -c "${project_dir}/conf/test.config" 
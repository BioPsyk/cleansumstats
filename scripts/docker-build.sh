#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_dir=$(dirname "${script_dir}")

cd "${project_dir}"

echo ">> Building docker container"
docker build ./docker -t ibp-cleansumstats:latest

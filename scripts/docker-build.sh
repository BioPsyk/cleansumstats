#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

echo ">> Building docker container"
docker build ./docker -t "${image_tag}"

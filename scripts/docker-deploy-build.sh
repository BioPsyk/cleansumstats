#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

echo ">> Building deployment docker image"

docker build \
       -f ./docker/Dockerfile.deploy \
       -t "${deploy_image_tag}" \
       --build-arg BASE_IMAGE="${image_tag}" \
       .

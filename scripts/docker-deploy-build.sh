#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

echo ">> Building multi-arch deployment docker image"

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f ./docker/Dockerfile.deploy \
  --tag "${deploy_image_tag}" \
  --build-arg BASE_IMAGE="${image_tag}" \
  --push \
  .

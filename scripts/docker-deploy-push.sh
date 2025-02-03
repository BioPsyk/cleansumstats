#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

target="biopsyk/${deploy_image_tag}"

echo ">> Pushing multi-arch deployment docker image to Docker Hub"

# Create manifest for multi-arch image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f ./docker/Dockerfile.deploy \
  --tag "${target}" \
  --build-arg BASE_IMAGE="${image_tag}" \
  --push \
  .


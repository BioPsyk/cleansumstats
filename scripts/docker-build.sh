#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

echo ">> Setting up docker buildx for multi-arch support"
docker buildx create --name multiarch --driver docker-container --use || true
docker buildx inspect --bootstrap

echo ">> Building multi-arch base docker image"

# Build and load the image locally
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag "${image_tag}" \
  --load \
  ./docker "$@"

# If you want to push to Docker Hub, uncomment these lines and run docker login first
# docker tag "${image_tag}" "biopsyk/${image_tag}"
# docker push "biopsyk/${image_tag}"

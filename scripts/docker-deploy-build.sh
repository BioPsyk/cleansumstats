#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

echo ">> Building deployment docker images for multiple architectures"

VERSION=$(cat docker/VERSION)

# Build amd64
echo "Building amd64 image..."
docker build \
  --platform linux/amd64 \
  -f ./docker/Dockerfile.deploy \
  --tag "${deploy_image_tag}-amd64" \
  --build-arg VERSION="${VERSION}" \
  --build-arg BASE_IMAGE="${image_tag}" \
  .

# Build arm64
echo "Building arm64 image..."
docker build \
  --platform linux/arm64 \
  -f ./docker/Dockerfile.deploy \
  --tag "${deploy_image_tag}-arm64" \
  --build-arg VERSION="${VERSION}" \
  --build-arg BASE_IMAGE="${image_tag}" \
  .

# Tag the native architecture as the main tag
echo "Tagging native architecture as main image..."
if [ "$(uname -m)" = "arm64" ]; then
  docker tag "${deploy_image_tag}-arm64" "${deploy_image_tag}"
else
  docker tag "${deploy_image_tag}-amd64" "${deploy_image_tag}"
fi

echo "Multi-arch images built successfully!"
echo "Available tags:"
echo "- ${deploy_image_tag} (native architecture)"
echo "- ${deploy_image_tag}-amd64"
echo "- ${deploy_image_tag}-arm64"

# If you want to push to Docker Hub, uncomment and run these lines:
# echo "Creating multi-arch manifest for Docker Hub..."
# docker manifest create "biopsyk/${deploy_image_tag}" \
#   --amend "${deploy_image_tag}-amd64" \
#   --amend "${deploy_image_tag}-arm64"
# docker manifest push "biopsyk/${deploy_image_tag}"

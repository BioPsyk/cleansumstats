#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

target="biopsyk/${deploy_image_tag}"

echo ">> Pushing multi-arch deployment docker image to Docker Hub"

# Enable experimental features for manifest support
export DOCKER_CLI_EXPERIMENTAL=enabled

# Tag the architecture-specific images for Docker Hub
echo "Tagging images for Docker Hub..."
docker tag "${deploy_image_tag}-amd64" "${target}-amd64"
docker tag "${deploy_image_tag}-arm64" "${target}-arm64"

# Push the architecture-specific images and capture their digests
echo "Pushing architecture-specific images..."
amd64_digest=$(docker push "${target}-amd64" | grep digest | cut -d' ' -f3)
arm64_digest=$(docker push "${target}-arm64" | grep digest | cut -d' ' -f3)

echo "AMD64 digest: ${amd64_digest}"
echo "ARM64 digest: ${arm64_digest}"

# Create and push the multi-arch manifest
echo "Creating and pushing multi-arch manifest..."

# Clean up any existing manifest
docker manifest rm "${target}" 2>/dev/null || true

# Create new manifest with explicit digests
docker manifest create "${target}" \
  "docker.io/${target}-amd64@${amd64_digest}" \
  "docker.io/${target}-arm64@${arm64_digest}"

# Add platform annotations
docker manifest annotate "${target}" "docker.io/${target}-amd64@${amd64_digest}" --os linux --arch amd64
docker manifest annotate "${target}" "docker.io/${target}-arm64@${arm64_digest}" --os linux --arch arm64

echo "Pushing manifest..."
docker manifest push --purge "${target}"

# Wait a moment for Docker Hub to process the manifest
sleep 5

echo "Multi-arch image successfully pushed to Docker Hub as ${target}"
echo "Verifying manifest..."
docker manifest inspect "${target}" | cat

# Test pulling the manifest
echo "Testing manifest pull..."
docker manifest inspect "docker.io/${target}" | cat


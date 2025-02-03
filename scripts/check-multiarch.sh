#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

echo ">> Checking Docker buildx setup..."
if docker buildx ls | grep -q "multiarch"; then
    echo "✓ Multiarch builder exists"
else
    echo "✗ Multiarch builder not found"
fi

echo -e "\n>> Checking current builder..."
docker buildx ls | grep -E "^[*]"

echo -e "\n>> Checking image architecture support..."

check_image() {
    local image_name="$1"
    echo "Checking image: ${image_name}"
    
    # First check if image exists at all
    if ! docker image inspect "${image_name}" >/dev/null 2>&1; then
        echo "✗ Image not found"
        return
    fi
    
    # If image exists, check for multi-arch support
    if docker buildx imagetools inspect "${image_name}" >/dev/null 2>&1; then
        echo "✓ Image exists with multi-arch support"
        echo "Architectures supported:"
        docker buildx imagetools inspect "${image_name}" | grep -A 5 "Platform:"
    else
        echo "⚠ Image exists but without multi-arch support"
        echo "Current architecture only:"
        docker image inspect "${image_name}" | grep "Architecture" | head -n 1
    fi
    echo ""
}

# Check base image
check_image "${image_tag}"

# Check deployment image
check_image "${deploy_image_tag}"

# Check Docker Hub image
check_image "biopsyk/${deploy_image_tag}" 
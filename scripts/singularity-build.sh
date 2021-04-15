#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${script_dir}/init-containerization.sh"

exec singularity build tmp/${singularity_image_tag} \
     docker-daemon:"${image_tag}"


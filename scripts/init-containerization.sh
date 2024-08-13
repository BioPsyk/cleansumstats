#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_dir=$(dirname "${script_dir}")

function format_mount_flags() {
  flag="${1}"

  for mount in "${mounts[@]}"
  do
    echo "${flag} ${project_dir}/${mount}:/cleansumstats/${mount} "
  done
}

cd "${project_dir}"

mounts=(
  "docs" "assets" "bin" "conf" "modules"
  "main.nf" "nextflow.config" "tests" "tmp" "lib"
  "VERSION"
)

image_tag="ibp-cleansumstats-base:"$(cat "docker/VERSION")
deploy_image_tag="ibp-cleansumstats:"$(cat "docker/VERSION")
deploy_image_tag_docker_hub="biopsyk/ibp-cleansumstats:"$(cat "docker/VERSION")

#singularity build
singularity_image_tag="ibp-cleansumstats-base_version-$(cat "docker/VERSION").sif"

mkdir -p tmp

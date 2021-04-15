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

if [ -d "sumstat_reference" ];
then
  mounts=(
    "docs" "assets" "bin" "conf" "environment.yml"
    "main.nf" "nextflow.config" "tests" "tmp" "lib"
    "sumstat_reference"
  )
else
  mounts=(
    "docs" "assets" "bin" "conf" "environment.yml"
    "main.nf" "nextflow.config" "tests" "tmp" "lib"
  )
fi

image_tag="ibp-cleansumstats-base:"$(cat "docker/VERSION")
deploy_image_tag="ibp-cleansumstats:"$(cat "docker/VERSION")

#singularity build
singularity_image_tag="ibp-cleansumstats-base_version-$(cat "docker/VERSION").simg"

mkdir -p tmp

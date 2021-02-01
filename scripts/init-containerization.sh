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
  "docs" "assets" "bin" "conf" "environment.yml"
  "main.nf" "nextflow.config" "tests" "tmp" "lib"
)

image_tag="ibp-cleansumstats:"$(cat "docker/VERSION")

mkdir -p tmp

#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

cd "${project_dir}"

target="public.ecr.aws/y5a4r2h0/${deploy_image_tag}"

echo ">> Pushing deployment docker image"

docker tag "${deploy_image_tag}" "${target}"
docker push "${target}"

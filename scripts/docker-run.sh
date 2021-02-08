#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${script_dir}/init-containerization.sh"

mount_flags=$(format_mount_flags "-v")

exec docker run --rm ${mount_flags} "${image_tag}" "$@"

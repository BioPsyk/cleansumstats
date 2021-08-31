#!/usr/bin/env bash

# This script is a wrapper to run the singularity image of this pipeline, where folders are parsed and mounted in the right place.

# This script takes two required inputs, which directories have to be mounted: 
# --input
# --outdir


# For now we will hardcode the other possible input types (and use path set in README):
#--libdirdbsnp ./out_dbsnp \
#--kg1000AFGRCh38 ./out_1kgp
#

# This script is run like this:
# cleansumstats.sh "metadatafile" "outfolder"

# OR like this:
# cleansumstats.sh "metadatafile" "outfolder" "test"

# Example paths can look like this
# input: /home/joeri/blabla/metadata.yaml
# out_dir: /faststorage/project/gwas/results/

# check both arguments exist
if [ -z $1 ]; then
  >&2 echo "First argument not given (metadatafile)"
  exit 1
fi
if [ -z $2 ]; then
  >&2 echo "Second argument not given (outdir)"
  exit 1
fi

metafile_host=$(realpath "${1}")
outdir_host=$(realpath "${2}")

# Test that file and folder exists
if [ ! -f $metafile_host ]; then
  >&2 echo "metafile doesn't exist"
  exit 1
fi
if [ ! -d $outdir_host ]; then
  >&2 echo "outdir doesn't exist"
  exit 1
fi

# For testing purposes we can use the test flag to run on a smaller reference set of dbsnp and 1kgp
# check test argument exist
if [ -z $3 ]; then
  libdirdbsnp="./out_dbsnp"
  kg1000AFGRCh38="./out_1kgp"
else
  if [ "$3"=="test" ]; then
    kg1000AFGRCh38="/cleansumstats/tests/example_data/1kgp/generated_reference/1kg_af_ref.sorted.joined"
    libdirdbsnp="/cleansumstats/tests/example_data/dbsnp/generated_reference"
  else
    >&2 echo "test argument has to be 'test'"
    exit 1
  fi
fi

# All paths we see will start from the project root, even if the command is called from somewhere else
project_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${project_dir}/scripts/init-containerization.sh"

mount_flags=$(format_mount_flags "-B")

metadir_host=$(dirname "${metafile_host}")
metafile_name=$(basename "${metafile_host}")
metadir_container="/cleansumstats/input"
metafile_container="${metadir_container}/${metafile_name}"
outdir_container="/cleansumstats/out"

FAKE_HOME="tmp/fake-home"
export SINGULARITY_HOME="/cleansumstats/${FAKE_HOME}"
mkdir -p "${FAKE_HOME}"

exec singularity run \
     --contain \
     --cleanenv \
     ${mount_flags} \
     -B "${metadir_host}:${metadir_container}" \
     -B "${outdir_host}:${outdir_container}" \
     "tmp/${singularity_image_tag}" \
     nextflow run /cleansumstats \
       --input "${metafile_container}" \
       --outdir "${outdir_container}" \
       --libdirdbsnp "${libdirdbsnp}" \
       --kg1000AFGRCh38 "${kg1000AFGRCh38}"


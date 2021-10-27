#!/usr/bin/env bash

# This script is a wrapper to run the singularity image of this pipeline, where folders are parsed and mounted in the right place.

################################################################################
# Help page
################################################################################

function general_usage(){
 echo "Example usage, specify output and the test flag:"
 echo " ./cleansumstats.sh -o output -t"
 echo ""
 echo "Simple Usage:"
 echo " ./cleansumstats.sh -i <file> -o <dir>"
 echo ""
 echo "Advanced Usage:"
 echo " ./cleansumstats.sh -i <file> -o <dir> -d <dir> -k <dir>"
 echo ""
 echo "options:"
 echo "-h		 Display help message for cleansumstats"
 echo "-i <file> 	 path to meta file"
 echo "-o <dir> 	 path to output directory"
 echo "-d <dir> 	 path to dbsnp processed reference"
 echo "-k <dir> 	 path to 1000 genomes processed reference"
 echo "-t  	 	 test the example version of dbsnp and 1000 genomes references"
 echo ""
 echo ""
 echo "NOTE: For 'simple usage' it requires dbsnp and 1000G project references to be set up and linked to in the config file."

}


################################################################################
# Parameter parsing
################################################################################
#whatever the input make it array
paramarray=($@)

# starting getops with :, puts the checking in silent mode for errors.
getoptsstring=":hvi:o:d:k:t"

# Set default dbsnpdir to where the files are automatically placed when
# following the instrucitons in the README.md
# NOTE: Remember to symlink back here in case these files are moved to a 
#       shared resources folder.
dbsnpdir="tmp/fake-home/out_dbsnp"
kgpfile="tmp/fake-home/out_1kgp/1kg_af_ref.sorted.joined"

metafileexists=false
outdirexists=false
testoption=false

while getopts "${getoptsstring}" opt "${paramarray[@]}"; do
  case ${opt} in
    h )
      general_usage 1>&2
      exit 0
      ;;
    v )
      #write a something that parses the actual version number
      echo "Version: 1.0.0" 1>&2
      exit 0
      ;;
    i )
      metafile="$OPTARG"
      metafileexists=true
      ;;
    o )
      outdir="$OPTARG"
      outdirexists=true
      ;;
    d )
      dbsnpdir="$OPTARG"
      ;;
    k )
      kgpfile="$OPTARG"
      ;;
    t )
      testoption=true
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done

################################################################################
# Check test option
################################################################################

# For testing purposes we can use the test flag to run on a smaller reference
# set of dbsnp and 1kgp
# check test argument exist
if $testoption; then
  # give path to example data
  if $metafileexists; then
    :
  else
    metafile="tests/example_data/sumstat_1/sumstat_1_raw_meta.txt"
  fi
  if $outdirexists; then
    :
  else
    outdir="out_test"
  fi
  dbsnpdir="tests/example_data/dbsnp/generated_reference"
  kgpfile="tests/example_data/1kgp/generated_reference/1kg_af_ref.sorted.joined"
  mkdir -p ${outdir}
fi

################################################################################
# Check if the provided paths exist
################################################################################

metafile_host=$(realpath "${metafile}")
outdir_host=$(realpath "${outdir}")
dbsnpdir_host=$(realpath "${dbsnpdir}")
kgpfile_host=$(realpath "${kgpfile}")

# Test that file and folder exists
if [ ! -f $metafile_host ]; then
  >&2 echo "metafile doesn't exist"
  exit 1
fi
if [ ! -d $outdir_host ]; then
  >&2 echo "outdir doesn't exist"
  exit 1
fi
if [ ! -d $dbsnpdir_host ]; then
  >&2 echo "dbsnpdir doesn't exist"
  exit 1
fi
if [ ! -f $kgpfile_host ]; then
  >&2 echo "kgpfile doesn't exist"
  exit 1
fi


################################################################################
# Prepare container variables
################################################################################

# All paths we see will start from the project root, even if the command is called from somewhere else
project_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${project_dir}/scripts/init-containerization.sh"

mount_flags=$(format_mount_flags "-B")

# metadir
metadir_host=$(dirname "${metafile_host}")
metafile_name=$(basename "${metafile_host}")
metadir_container="/cleansumstats/input"
metafile_container="${metadir_container}/${metafile_name}"

# outdir
outdir_container="/cleansumstats/outdir"

# dbsnpdir
dbsnpdir_container="/cleansumstats/dbsnp"

# kgpdir
kgpdir_host=$(dirname "${kgpfile_host}")
kgpfile_name=$(basename "${kgpfile_host}")
kgpdir_container="/cleansumstats/kgpdir"
kgpfile_container="${kgpdir_container}/${kgpfile_name}"


FAKE_HOME="tmp/fake-home"
export SINGULARITY_HOME="/cleansumstats/${FAKE_HOME}"
mkdir -p "${FAKE_HOME}"

exec singularity run \
     --contain \
     --cleanenv \
     ${mount_flags} \
     -B "${metadir_host}:${metadir_container}" \
     -B "${outdir_host}:${outdir_container}" \
     -B "${dbsnpdir_host}:${dbsnpdir_container}" \
     -B "${kgpdir_host}:${kgpdir_container}" \
     "tmp/${singularity_image_tag}" \
     nextflow run /cleansumstats \
       --input "${metafile_container}" \
       --outdir "${outdir_container}" \
       --libdirdbsnp "${dbsnpdir_container}" \
       --kg1000AFGRCh38 "${kgpfile_container}"


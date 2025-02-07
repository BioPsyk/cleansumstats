#!/usr/bin/env bash

# This script is a wrapper to run the singularity image of this pipeline, where folders are parsed and mounted in the right place.

################################################################################
# Help page
################################################################################

function general_usage(){
 echo "Usage:"
 echo " ./cleansumstats.sh -i <file> -o <dir> -d <dir> -k <dir>"
 echo ""
 echo "Example usage, using the quick example flag:"
 echo " ./cleansumstats.sh -o <dir> -e"
 echo ""
 echo "Generate references:"
 echo " ./cleansumstats.sh prepare-dbsnp -i <file> -o <dir>"
 echo " ./cleansumstats.sh prepare-1kgp -i <file> -d <dir> -o <dir>"
 echo ""
 echo "options:"
 echo "-h		 Display help message for cleansumstats"
 echo "-i <file> 	 path to infile"
 echo "-o <dir> 	 path to output directory"
 echo "-d <dir> 	 path to dbsnp processed reference"
 echo "-k <dir> 	 path to 1000 genomes processed reference"
 echo "-b <dir> 	 path to system tmp or scratch (default: /tmp)"
 echo "-w <dir> 	 path to workdir/intermediate files (default: work)"
 echo "-p path1:path2 	 path to metadata associated folders"
 echo "-t  	 	 quick test for all paths and params"
 echo "-e  	 	 quick example run using shrinked dbsnp and 1000 genomes references"
 echo "-l  	 	 dev mode, saving intermediate files, no cleanup of workdir(default: not active)"
 echo "-j  	 	 image mode, run docker, dockerhub_biopsyk or singularity (if unset or empty: singularity)"
 echo "-v  	 	 get the version number"
}

# If no arguments are provided, display usage and exit
if [ "$#" -eq 0 ]; then
    general_usage
    exit 0
fi

################################################################################
# Prepare path parsing
################################################################################
# All paths we see will start from the project root, even if the command is called from somewhere else
present_dir="${PWD}"
project_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

################################################################################
# Parameter parsing
################################################################################
# whatever the input make it array
paramarray=($@)

# check for modifiers
if [ ${paramarray[0]} == "prepare-dbsnp" ] ; then
  runtype="prepare-dbsnp"
  # remove modifier, 1st element
  paramarray=("${paramarray[@]:1}")
elif [ ${paramarray[0]} == "prepare-1kgp" ] ; then
  runtype="prepare-1kgp"
  # remove modifier, 1st element
  paramarray=("${paramarray[@]:1}")
elif [ ${paramarray[0]} == "test" ] ; then
  runtype="test"
  paramarray=("${paramarray[@]:1}")
elif [ ${paramarray[0]} == "utest" ] ; then
  runtype="utest"
  paramarray=("${paramarray[@]:1}")
elif [ ${paramarray[0]} == "etest" ] ; then
  runtype="etest"
  paramarray=("${paramarray[@]:1}")
else
  runtype="default"
fi


# starting getops with :, puts the checking in silent mode for errors.
getoptsstring=":hvi:o:d:k:b:w:p:e:j:tl"

# Set default dbsnpdir to where the files are automatically placed when
# following the instrucitons in the README.md
# NOTE: If you are a sysadmin, remember to symlink back here in case these files are moved to a 
#       shared resources folder.
dbsnpdir="${project_dir}/out_dbsnp"
kgpdir="${project_dir}/out_1kgp"
infile=""
outdir="out"
container_image=""

# some logical defaults
infile_given=false
outdir_given=false
dbsnpdir_given=false
kgpdir_given=false
tmpdir_given=false
extrapaths_given=false
devmode_given=false
container_image_given=false
pathquicktest=false
runexampledata=false

# default extrapaths values
unset extrapaths
unset extrapaths2

# default system tmp
tmpdir="/tmp"
workdir="${present_dir}/work"
devmode=""

while getopts "${getoptsstring}" opt "${paramarray[@]}"; do
  case ${opt} in
    h )
      general_usage 1>&2
      exit 0
      ;;
    v )
      #write a something that parses the actual version number
      cat ${project_dir}/VERSION 1>&2
      exit 0
      ;;
    i )
      infile="$OPTARG"
      infile_given=true
      ;;
    o )
      outdir="$OPTARG"
      outdir_given=true
      ;;
    d )
      dbsnpdir="$OPTARG"
      dbsnpdir_given=true
      ;;
    k )
      kgpdir="$OPTARG"
      kgpdir_given=true
      ;;
    b )
      tmpdir="$OPTARG"
      tmpdir_given=true
      ;;
    w )
      workdir="$OPTARG"
      workdir_given=true
      ;;
    p )
      extrapaths="$OPTARG"
      extrapaths_given=true
      ;;
    e )
      runexampledatanr="$OPTARG"
      runexampledata=true
      ;;
    l )
      devmode="--dev"
      devmode_given=true
      ;;
    j )
      container_image="$OPTARG"
      container_image_given=true
      ;;
    t )
      pathquicktest=true
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
# Check quick-run example options
################################################################################
# give path to example data
if $runexampledata; then
  if [ "${runtype}" == "generateDbSNPreference" ] ; then
    if ${infile_given}; then
      :
    else
      infile="${project_dir}/tests/example_data/dbsnp/GCF_000001405.40_reduced.gz"
    fi
    if ${outdir_given}; then
      :
    else
      outdir="out_dbsnp_test"
    fi
    dbsnpdir=${outdir}
    #won't be used, but needs to be set
    kgpdir="${project_dir}/tests/example_data/1kgp/generated_reference"

  elif [ "${runtype}" == "generate1KgAfSNPreference" ] ; then
    if ${infile_given}; then
      :
    else
      infile="${project_dir}/tests/example_data/1kgp/1kg_example_data.vcf.gz"
    fi
    if ${outdir_given}; then
      :
    else
      outdir="out_1kgp_test"
    fi
    if ${dbsnpdir_given}; then
      :
    else
      dbsnpdir="${project_dir}/tests/example_data/dbsnp/generated_reference"
    fi
    kgpdir=${outdir}

  elif [ "${runtype}" == "default" ] ; then
    if ${infile_given}; then
      :
    else
      if [ "${runexampledatanr}" == "1" ] ; then
        infile="${project_dir}/tests/example_data/sumstat_1/sumstat_1_raw_meta.txt"
      elif [ "${runexampledatanr}" == "2" ] ; then
        infile="${project_dir}/tests/example_data/sumstat_2/sumstat_2_raw_meta.txt"
      else
        infile="${project_dir}/tests/example_data/sumstat_1/sumstat_1_raw_meta.txt"
      fi
    fi
    if ${outdir_given}; then
      :
    else
      outdir="out_test"
    fi
    dbsnpdir="${project_dir}/tests/example_data/dbsnp/generated_reference"
    kgpdir="${project_dir}/tests/example_data/1kgp/generated_reference"
  else
    echo "${runtype}"
    echo "unknown runtype"
  fi
elif [ "${runtype}" == "test" ] || [ "${runtype}" == "utest" ] || [ "${runtype}" == "etest" ]; then
  # All are placeholders and not used
  infile="${project_dir}/VERSION"
  outdir="${outdir}"
  dbsnpdir="${outdir}"
  kgpdir="${outdir}"
fi

################################################################################
# Check if the provided paths exist
################################################################################

# make outdir if it doesn't already exist
mkdir -p ${outdir}

# make workdir if it doesn't already exist
mkdir -p ${workdir}

# make workdir if it doesn't already exist
mkdir -p ${tmpdir}

infile_host=$(realpath "${infile}")
outdir_host=$(realpath "${outdir}")

# check for modifiers
if [ "${runtype}" == "--generateDbSNPreference" ] ; then
  # use outdir as landing directory for all output
  dbsnpdir="${outdir}"
  kgpdir="${outdir}"
elif [ "${runtype}" == "--generate1KgAfSNPreference" ] ; then
  # use outdir as landing directory for all output
  kgpdir=${outdir}
else
  :
fi
dbsnpdir_host=$(realpath "${dbsnpdir}")
kgpdir_host=$(realpath "${kgpdir}")
tmpdir_host=$(realpath "${tmpdir}")
workdir_host=$(realpath "${workdir}")

# Test that file and folder exists, all of these will always get mounted
if [ ! -f $infile_host ]; then
  >&2 echo "infile doesn't exist"
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
if [ ! -d $kgpdir_host ]; then
  >&2 echo "kgpdir doesn't exist"
  exit 1
fi
if [ ! -d $tmpdir_host ]; then
  >&2 echo "tmpdir doesn't exist"
  exit 1
fi
if [ ! -d $workdir_host ]; then
  >&2 echo "workdir doesn't exist"
  exit 1
fi

# Add metadata env variable folders (fix realpath)
if ${extrapaths_given} ;
then
  extrapaths2="$(echo ${extrapaths} | sed 's/,/\n/g' | xargs realpath | awk -vOFS="" '{printf "%s%s%s%s%s", "-B ", $1,":/cleansumstats/extrabind/fold",++count," "}; END{printf "%s", RS}')"
  extrapaths3="$(echo ${extrapaths} | sed 's/,/\n/g' | awk -vOFS="," '{printf "%s%s%s", "/cleansumstats/extrabind/fold",++count,","}; END{printf "%s", RS}' | sed 's/\(.*\),/\1 /')"
else
  extrapaths2=""
  extrapaths3=""
fi


################################################################################
# Prepare container variables
################################################################################

# All paths we see will start from the project root, even if the command is called from somewhere else
project_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# indir
indir_host=$(dirname "${infile_host}")
infile_name=$(basename "${infile_host}")
indir_container="/cleansumstats/input"
infile_container="${indir_container}/${infile_name}"

# outdir
outdir_container="/cleansumstats/outdir"

# dbsnpdir
dbsnpdir_container="/cleansumstats/dbsnp"

# tmpdir
tmpdir_container="/tmp"

# workdir
workdir_container="/cleansumstats/work"

# kgpdir
kgpfile_name="1kg_af_ref.txt"
kgpdir_container="/cleansumstats/kgpdir"
kgpfile_container="${kgpdir_container}/${kgpfile_name}"


# Use outdir as fake home to avoid lock issues for the hidden .nextflow/history file
#FAKE_HOME="${outdir_container}"
#export SINGULARITY_HOME="${FAKE_HOME}"
#export APPTAINER_HOME="${FAKE_HOME}"

## Set Nextflow environment variables for the launching environment
#export NXF_OFFLINE='true'
## Set both SINGULARITYENV and APPTAINERENV for better compatibility
#export SINGULARITYENV_NXF_OFFLINE='true'
#export APPTAINERENV_NXF_OFFLINE='true'


# Previous fake home, causing #FAKE_HOME="tmp/fake-home"
#export SINGULARITY_HOME="/cleansumstats/${FAKE_HOME}"
#mkdir -p "${FAKE_HOME}"

if [ "${runtype}" == "default" ]; then
  run_script="/cleansumstats/main.nf"
elif [ "${runtype}" == "test" ]; then
  run_script="/cleansumstats/tests/run-tests.sh"
elif [ "${runtype}" == "utest" ]; then
  run_script="/cleansumstats/tests/run-unit-tests.sh"
elif [ "${runtype}" == "etest" ]; then
  mkdir -p tmp
  run_script="/cleansumstats/tests/run-e2e-tests.sh"
elif [ "${runtype}" == "prepare-dbsnp" ]; then
  run_script="/cleansumstats --generateDbSNPreference"
elif [ "${runtype}" == "prepare-1kgp" ]; then
  run_script="/cleansumstats --generate1KgAfSNPreference"
else
  echo "option not available"
  exit 1
fi

source "${project_dir}/scripts/init-containerization.sh"

# Which image is to be used
if [ "${container_image}" == "docker" ]; then
  runimage="${image_tag}" 
elif [ "${container_image}" == "dockerhub_biopsyk" ]; then
  runimage="${deploy_image_tag_docker_hub}" 
elif [ "${container_image}" == "" ]; then
  #if not set, assume image is in sif folder
  runimage="sif/${singularity_image_tag}" 
else
  runimage="${container_image}" 
fi

if ${pathquicktest}; then
 echo "cleansumstats.sh to-mount"
 echo "------------------"
 echo "infile: ${infile}"
 echo "outdir: ${outdir}"
 echo "dbsnpdir: ${dbsnpdir}"
 echo "kgpdir: ${kgpdir}"
 echo "tmpdir: ${tmpdir}"
 echo ""
 echo "cleansumstats.sh logic"
 echo "------------------"
 echo "infile_given: ${infile_given}"
 echo "outdir_given: ${outdir_given}"
 echo "kgpdir_given: ${kgpdir_given}"
 echo "dbsnpdir_given: ${dbsnpdir_given}"
 echo "extrapths_given: ${dbsnpdir_given}"
 echo "pathquicktest: ${pathquicktest}"
 echo "runexampledata: ${runexampledata}"
 echo ""
 echo "Singularity mounts"
 echo "------------------"
 echo "indir_host:indir_container ${indir_host}:${indir_container}"
 echo "outdir_host:outdir_container ${outdir_host}:${outdir_container}"
 echo "dbsnpdir_host:dbsnpdir_container: ${dbsnpdir_host}:${dbsnpdir_container}"
 echo "kgpdir_host:kgpdir_container: ${kgpdir_host}:${kgpdir_container}"
 echo ""
 echo "Singularity image used"
 echo "------------------"
 echo "tmp/${singularity_image_tag}" 
 echo "tmp/${docker_image_tag}" 
 echo ""
 echo "Nextflow flags"
 echo "------------------"
 echo "--input ${infile_container}"
 echo "--outdir ${outdir_container}"
 echo "--libdirdbsnp ${dbsnpdir_container}"
 echo "--kg1000AFGRCh38 ${kgpfile_container}"
elif [ "${runtype}" == "test" ] || [ "${runtype}" == "utest" ] || [ "${runtype}" == "etest" ]; then
  if [ "${container_image}" == "dockerhub_biopsyk" ]; then
    echo "container: $runimage"
    mount_flags=$(format_mount_flags "-v")
    exec docker run --rm ${mount_flags} "${runimage}" ${run_script}
  elif [ "${container_image}" == "docker" ]; then
    echo "container: $runimage"
    mount_flags=$(format_mount_flags "-v")
    exec docker run --rm ${mount_flags} "${runimage}" ${run_script}
  else
    echo "container: $runimage"
    mount_flags=$(format_mount_flags "-B")
    singularity run \
       --net \
       --network none \
       --cleanenv \
       --containall \
       --home "${outdir_container}" \
       ${mount_flags} \
       "${runimage}" \
       ${run_script}
  fi
elif [ "${container_image}" == "dockerhub_biopsyk" ]; then
  echo "container: $runimage"
  mount_flags=$(format_mount_flags "-v")
  exec docker run \
     --rm \
     ${mount_flags} \
     -v "${indir_host}:${indir_container}" \
     -v "${outdir_host}:${outdir_container}" \
     -v "${dbsnpdir_host}:${dbsnpdir_container}" \
     -v "${kgpdir_host}:${kgpdir_container}" \
     -v "${tmpdir_host}:${tmpdir_container}" \
     -v "${workdir_host}:${workdir_container}" \
     "${runimage}" \
     nextflow \
       -log "${outdir_container}/.nextflow.log" \
       run ${run_script} \
       --extrapaths ${extrapaths3} \
       ${devmode} \
       --input "${infile_container}" \
       --outdir "${outdir_container}" \
       --libdirdbsnp "${dbsnpdir_container}" \
       --kg1000AFGRCh38 "${kgpfile_container}"
elif [ "${container_image}" == "docker" ]; then
  echo "container: $runimage"
  mount_flags=$(format_mount_flags "-v")
  exec docker run \
     --rm \
     ${mount_flags} \
     -v "${indir_host}:${indir_container}" \
     -v "${outdir_host}:${outdir_container}" \
     -v "${dbsnpdir_host}:${dbsnpdir_container}" \
     -v "${kgpdir_host}:${kgpdir_container}" \
     -v "${tmpdir_host}:${tmpdir_container}" \
     -v "${workdir_host}:${workdir_container}" \
     "${runimage}" \
     nextflow \
       -log "${outdir_container}/.nextflow.log" \
       run ${run_script} \
       --extrapaths ${extrapaths3} \
       ${devmode} \
       --input "${infile_container}" \
       --outdir "${outdir_container}" \
       --libdirdbsnp "${dbsnpdir_container}" \
       --kg1000AFGRCh38 "${kgpfile_container}"
else
  echo "container: $runimage"
  mount_flags=$(format_mount_flags "-B")
  
  singularity run \
     --net \
     --network none \
     --no-eval \
     --cleanenv \
     --containall \
     --home "${outdir_container}" \
     ${mount_flags} \
     ${extrapaths2} \
     -B "${indir_host}:${indir_container}" \
     -B "${outdir_host}:${outdir_container}" \
     -B "${dbsnpdir_host}:${dbsnpdir_container}" \
     -B "${kgpdir_host}:${kgpdir_container}" \
     -B "${tmpdir_host}:${tmpdir_container}" \
     -B "${workdir_host}:${workdir_container}" \
     "${runimage}" \
     nextflow \
       -log "${outdir_container}/.nextflow.log" \
       run ${run_script} \
       --extrapaths ${extrapaths3} \
       ${devmode} \
       --input "${infile_container}" \
       --outdir "${outdir_container}" \
       --libdirdbsnp "${dbsnpdir_container}" \
       --kg1000AFGRCh38 "${kgpfile_container}"
fi

if ${pathquicktest}; then
  echo "When running quick test we do not clean"
elif [ "${runtype}" == "test" ] || [ "${runtype}" == "utest" ] || [ "${runtype}" == "etest" ]; then
  echo "When running tests there is nothing to clean"
else
  #Set correct permissions to pipeline_info files
  chmod -R ugo+rwX ${outdir_host}/pipeline_info

  #remove .nextflow directory by default
  if ${devmode_given} ;
  then
    :
  else
    function cleanup {
      echo ">> Cleaning up (disable with -l) "
      echo ">> Removing ${outdir_host}/.nextflow"
      rm -r ${outdir_host}/.nextflow
      echo ">> Done"
    }
    trap cleanup EXIT
  fi  # Close the if ${devmode_given} block
fi  # Close the outer if ${pathquicktest} block

echo "cleansumstats.sh reached the end: $(date)"

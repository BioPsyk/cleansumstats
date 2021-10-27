#!/usr/bin/env bash

# This script is a wrapper to run the singularity image of this pipeline, where folders are parsed and mounted in the right place.

################################################################################
# Help page
################################################################################

function general_usage(){
 echo "Simple Usage:"
 echo " ./cleansumstats.sh -i <file> -o <dir>"
 echo ""
 echo "Advanced Usage:"
 echo " ./cleansumstats.sh -i <file> -o <dir> -d <dir> -k <dir>"
 echo ""
 echo "Example usage, using the quick example flag:"
 echo " ./cleansumstats.sh -o <dir> -e"
 echo ""
 echo "Generate references:"
 echo " ./cleansumstats.sh prepare-dbsnp -i <file> -o <dir>"
 echo " ./cleansumstats.sh prepare-1kgp -i <file> -o <dir>"
 echo ""
 echo "options:"
 echo "-h		 Display help message for cleansumstats"
 echo "-i <file> 	 path to infile"
 echo "-o <dir> 	 path to output directory"
 echo "-d <dir> 	 path to dbsnp processed reference"
 echo "-k <dir> 	 path to 1000 genomes processed reference"
 echo "-t  	 	 quick test for all paths and params"
 echo "-e  	 	 quick example run using shrinked dbsnp and 1000 genomes references"
 echo ""
 echo ""
 echo "NOTE: For 'simple usage' it requires dbsnp and 1000G project references to be prepared"

}


################################################################################
# Parameter parsing
################################################################################
# whatever the input make it array
paramarray=($@)

# check for modifiers
if [ ${paramarray[0]} == "prepare-dbsnp" ] ; then
  runtype="prepdbsnp"
  # remove modifier, 1st element
  paramarray=("${paramarray[@]:1}")
elif [ ${paramarray[0]} == "prepare-1kgp" ] ; then
  runtype="prep1kgp"
  # remove modifier, 1st element
  paramarray=("${paramarray[@]:1}")
else
  runtype="normalrun"
fi


# starting getops with :, puts the checking in silent mode for errors.
getoptsstring=":hvi:o:d:k:te"

# Set default dbsnpdir to where the files are automatically placed when
# following the instrucitons in the README.md
# NOTE: If you are a sysadmin, remember to symlink back here in case these files are moved to a 
#       shared resources folder.
dbsnpdir="out_dbsnp"
kgpdir="out_1kgp"
infile=""
outdir=""

# some logical defaults
infile_given=false
outdir_given=false
dbsnpdir_given=false
kgpdir_given=false
pathquicktest=false
runexampledata=false

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
      kgpfile="$OPTARG"
      kgpdir_given=true
      ;;
    e )
      runexampledata=true
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
  if [ ${runtype} == "prepdbsnp" ] ; then
    if ${infile_given}; then
      :
    else
      infile="tests/example_data/dbsnp/All_20180418_example_data.vcf.gz"
    fi
    if ${outdir_given}; then
      :
    else
      outdir="out_dbsnp_test"
    fi
    dbsnpdir=${outdir}

  elif [ ${runtype} == "prep1kgp" ] ; then
    if ${infile_given}; then
      :
    else
      infile="tests/example_data/1kgp/1kg_example_data.vcf.gz"
    fi
    if ${outdir_given}; then
      :
    else
      outdir="out_1kgp_test"
    fi
    if ${dbsnpdir_given}; then
      :
    else
      dbsnpdir="out_dbsnp_test"
    fi
    kgpdir=${outdir}

  elif [ ${runtype} == "normalrun" ] ; then
    if ${infile_given}; then
      :
    else
      infile="tests/example_data/sumstat_1/sumstat_1_raw_meta.txt"
    fi
    if ${outdir_given}; then
      :
    else
      outdir="out_test"
    fi
    dbsnpdir="tests/example_data/dbsnp/generated_reference"
    kgpdir="tests/example_data/1kgp/generated_reference"
  else
    echo "${runtype}"
    echo "unknown runtype"
  fi

fi

################################################################################
# Check if the provided paths exist
################################################################################

# make outdir if it doesn't already exist
mkdir -p ${outdir}

infile_host=$(realpath "${infile}")
outdir_host=$(realpath "${outdir}")
dbsnpdir_host=$(realpath "${dbsnpdir}")
kgpdir_host=$(realpath "${kgpdir}")

# Test that file and folder exists
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


################################################################################
# Prepare container variables
################################################################################

# All paths we see will start from the project root, even if the command is called from somewhere else
project_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${project_dir}/scripts/init-containerization.sh"

mount_flags=$(format_mount_flags "-B")

# indir
indir_host=$(dirname "${infile_host}")
infile_name=$(basename "${infile_host}")
indir_container="/cleansumstats/input"
infile_container="${indir_container}/${infile_name}"

# outdir
outdir_container="/cleansumstats/outdir"

# dbsnpdir
dbsnpdir_container="/cleansumstats/dbsnp"

# kgpdir
kgpfile_name="1kg_af_ref.sorted.joined"
kgpdir_container="/cleansumstats/kgpdir"
kgpfile_container="${kgpdir_container}/${kgpfile_name}"


FAKE_HOME="tmp/fake-home"
export SINGULARITY_HOME="/cleansumstats/${FAKE_HOME}"
mkdir -p "${FAKE_HOME}"

if ${pathquicktest}; then
 echo "cleansumstats.sh to-mount"
 echo "------------------"
 echo "infile: ${infile}"
 echo "outdir: ${outdir}"
 echo "dbsnpdir: ${dbsnpdir}"
 echo "kgpdir: ${kgpdir}"
 echo ""
 echo "cleansumstats.sh logic"
 echo "------------------"
 echo "infile_given: ${infile_given}"
 echo "outdir_given: ${outdir_given}"
 echo "kgpdir_given: ${kgpdir_given}"
 echo "dbsnpdir_given: ${dbsnpdir_given}"
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
 echo ""
 echo "Nextflow flags"
 echo "------------------"
 echo "--input ${infile_container}"
 echo "--outdir ${outdir_container}"
 echo "--libdirdbsnp ${dbsnpdir_container}"
 echo "--kg1000AFGRCh38 ${kgpfile_container}"
else
  if [ ${runtype} == "prepdbsnp" ] ; then
    echo "${runtype}"
    exec singularity run \
         --contain \
         --cleanenv \
         ${mount_flags} \
         -B "${indir_host}:${indir_container}" \
         -B "${outdir_host}:${outdir_container}" \
         -B "${dbsnpdir_host}:${dbsnpdir_container}" \
         "tmp/${singularity_image_tag}" \
         nextflow run /cleansumstats \
           --generateDbSNPreference \
           --input "${infile_container}" \
           --outdir "${outdir_container}" \
           --libdirdbsnp "${dbsnpdir_container}" 
  elif [ ${runtype} == "prep1kgp" ] ; then
    echo "${runtype}"
    exec singularity run \
         --contain \
         --cleanenv \
         ${mount_flags} \
         -B "${indir_host}:${indir_container}" \
         -B "${outdir_host}:${outdir_container}" \
         -B "${dbsnpdir_host}:${dbsnpdir_container}" \
         -B "${kgpdir_host}:${kgpdir_container}" \
         "tmp/${singularity_image_tag}" \
         nextflow run /cleansumstats \
	   --generate1KgAfSNPreference \
           --input "${infile_container}" \
           --outdir "${outdir_container}" \
           --libdirdbsnp "${dbsnpdir_container}" \
           --kg1000AFGRCh38 "${kgpfile_container}"
  elif [ ${runtype} == "normalrun" ] ; then
    echo "${runtype}"
    exec singularity run \
       --contain \
       --cleanenv \
       ${mount_flags} \
       -B "${indir_host}:${indir_container}" \
       -B "${outdir_host}:${outdir_container}" \
       -B "${dbsnpdir_host}:${dbsnpdir_container}" \
       -B "${kgpdir_host}:${kgpdir_container}" \
       "tmp/${singularity_image_tag}" \
       nextflow run /cleansumstats \
         --input "${infile_container}" \
         --outdir "${outdir_container}" \
         --libdirdbsnp "${dbsnpdir_container}" \
         --kg1000AFGRCh38 "${kgpfile_container}"
  else
    echo "${runtype}"
    echo "unknown runtype"
  fi
fi

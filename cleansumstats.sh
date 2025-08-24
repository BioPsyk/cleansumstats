#!/usr/bin/env bash

# This script is a wrapper to run the singularity image of this pipeline, where folders are parsed and mounted in the right place.

################################################################################
# Help page
################################################################################

# For devs:
#  - Short options work: -j docker, -i file, -o dir
#  - Long options work: --image docker, --input file, --output dir
#  - Mixed usage works: test -j docker or test --image docker
#  - The = syntax works: --input=file

function general_usage(){
 echo "Usage:"
 echo " ./cleansumstats.sh [OPTIONS]"
 echo " ./cleansumstats.sh COMMAND [OPTIONS]"
 echo ""
 echo "Available Commands:"
 echo " prepare-dbsnp    Generate dbSNP reference files"
 echo " prepare-1kgp     Generate 1000 Genomes reference files"
 echo " map-only         Map variants without full cleaning (ALL variants mapped)"
 echo " test             Run tests (use -h for test-specific options)"
 echo ""
 echo "Common Options:"
 echo " -h, --help                Display help message"
 echo " -v, --version             Display version number"
 echo " -i, --input <file>        Path to input metadata file"
 echo " -o, --output <dir>        Path to output directory"
 echo " -d, --dbsnp <dir>         Path to dbSNP processed reference"
 echo " -k, --1kgp, --kgp <dir>   Path to 1000 Genomes processed reference"
 echo " -b, --tmpdir <dir>        Path to system tmp or scratch (default: /tmp)"
 echo " -w, --workdir <dir>       Path to workdir/intermediate files (default: work)"
 echo " -p, --paths <path1:path2> Path to metadata associated folders"
 echo " -e, --example [1|2]       Quick example run using reduced test data"
 echo " -l, --dev                 Dev mode, saves intermediate files, no cleanup"
 echo " -j, --image <type>        Container image: docker, dockerhub_biopsyk, or singularity"
 echo " -t, --test                Quick test for all paths and params"
 echo ""
 echo "Examples:"
 echo " # Standard cleaning run"
 echo " ./cleansumstats.sh --input metadata.yaml --output results --dbsnp dbsnp_ref --1kgp kgp_ref"
 echo ""
 echo " # Quick example with reduced data"
 echo " ./cleansumstats.sh --output out_test --example 1"
 echo ""
 echo " # Get help for a specific command"
 echo " ./cleansumstats.sh test --help"
 echo " ./cleansumstats.sh prepare-dbsnp --help"
 echo ""
 echo "For more information on a specific command, use:"
 echo " ./cleansumstats.sh COMMAND --help"
}

function test_usage(){
 echo "Usage: ./cleansumstats.sh test [OPTIONS]"
 echo ""
 echo "Run tests for the cleansumstats pipeline. Requires a container (Docker or Singularity)."
 echo ""
 echo "Test Options:"
 echo " -h, --help          Display this help message"
 echo " -u, --unit          Run unit tests only"
 echo " -e, --e2e           Run end-to-end tests only"
 echo " -n, --name <test>   Run specific e2e test by name (use with -e)"
 echo " -j, --image <type>  Container to use: docker, dockerhub_biopsyk, or singularity"
 echo ""
 echo "Examples:"
 echo " # Run all tests"
 echo " ./cleansumstats.sh test --image docker"
 echo ""
 echo " # Run specific e2e test"
 echo " ./cleansumstats.sh test -e -n maponly_basics --image docker"
 echo ""
 echo " # Run unit tests only"
 echo " ./cleansumstats.sh test -u --image docker"
 echo ""
 echo " # Run end-to-end tests only"
 echo " ./cleansumstats.sh test -e --image docker"
 echo ""
 echo " # Run tests with specific container"
 echo " ./cleansumstats.sh test --image dockerhub_biopsyk"
}

function prepare_dbsnp_usage(){
 echo "Usage: ./cleansumstats.sh prepare-dbsnp [OPTIONS]"
 echo ""
 echo "Generate dbSNP reference files for the cleansumstats pipeline."
 echo ""
 echo "Required Options:"
 echo " -i, --input <file>   Path to dbSNP VCF file (e.g., GCF_000001405.40.gz)"
 echo " -o, --output <dir>   Output directory for generated reference files"
 echo ""
 echo "Optional:"
 echo " -h, --help           Display this help message"
 echo " -j, --image <type>   Container to use: docker, dockerhub_biopsyk, or singularity"
 echo " -l, --dev            Dev mode, saves intermediate files"
 echo ""
 echo "Examples:"
 echo " # Generate dbSNP reference from downloaded VCF"
 echo " ./cleansumstats.sh prepare-dbsnp --input dbsnp/GCF_000001405.40.gz --output out_dbsnp"
 echo ""
 echo " # Use with Docker container"
 echo " ./cleansumstats.sh prepare-dbsnp -i dbsnp.vcf.gz -o out_dbsnp --image docker"
 echo ""
 echo "Note: This process requires significant memory (400GB) and time (~5 hours)."
 echo "      For testing, use the -e flag with the main command for reduced test data."
}

function prepare_1kgp_usage(){
 echo "Usage: ./cleansumstats.sh prepare-1kgp [OPTIONS]"
 echo ""
 echo "Generate 1000 Genomes Project reference files for the cleansumstats pipeline."
 echo ""
 echo "Required Options:"
 echo " -i, --input <file>   Path to 1000 Genomes VCF file"
 echo " -d, --dbsnp <dir>    Path to prepared dbSNP reference directory"
 echo " -o, --output <dir>   Output directory for generated reference files"
 echo ""
 echo "Optional:"
 echo " -h, --help           Display this help message"
 echo " -j, --image <type>   Container to use: docker, dockerhub_biopsyk, or singularity"
 echo " -l, --dev            Dev mode, saves intermediate files"
 echo ""
 echo "Examples:"
 echo " # Generate 1KGP reference"
 echo " ./cleansumstats.sh prepare-1kgp --input 1kgp/1000GENOMES-phase_3.vcf.gz \\"
 echo "                                  --dbsnp out_dbsnp \\"
 echo "                                  --output out_1kgp"
 echo ""
 echo " # Use with Docker container"
 echo " ./cleansumstats.sh prepare-1kgp -i 1kgp.vcf.gz -d out_dbsnp -o out_1kgp --image docker"
 echo ""
 echo "Note: Requires dbSNP reference to be prepared first using prepare-dbsnp."
}

function map_only_usage(){
 echo "Usage: ./cleansumstats.sh map-only [OPTIONS]"
 echo ""
 echo "Map GWAS summary statistics to dbSNP references without full cleaning."
 echo "ALL variants are mapped using a two-step approach:"
 echo "  1. dbSNP mapping for common variants"
 echo "  2. Liftover fallback for unmapped variants (indels, rare/novel variants)"
 echo ""
 echo "Required Options:"
 echo " -i, --input <file>        Path to input metadata file"
 echo " -o, --output <dir>        Output directory for mapped files"
 echo " -d, --dbsnp <dir>         Path to dbSNP processed reference"
 echo ""
 echo "Optional:"
 echo " -h, --help                Display this help message"
 echo " -k, --1kgp <dir>          Path to 1000 Genomes reference (for AF)"
 echo " -j, --image <type>        Container: docker, dockerhub_biopsyk, or singularity"
 echo " --target-build <build>    Output genome build: GRCh37, GRCh38, or both (default)"
 echo " --apply-mapping           Apply mapping directly to input file (creates mapped sumstats)"
 echo " --keep-unmapped           Include unmapped variants in output"
 echo " --output-format <format>  Output format: full or minimal (default: minimal)"
 echo " -l, --dev                 Dev mode, saves intermediate files"
 echo ""
 echo "Examples:"
 echo " # Generate mapping files for both genome builds"
 echo " ./cleansumstats.sh map-only -i metadata.yaml -o mapped_output -d out_dbsnp"
 echo ""
 echo " # Map to GRCh38 and apply directly to input"
 echo " ./cleansumstats.sh map-only -i metadata.yaml -o mapped_output -d out_dbsnp \\"
 echo "                              --target-build GRCh38 --apply-mapping"
 echo ""
 echo " # Generate mapping file only (for manual paste later)"
 echo " ./cleansumstats.sh map-only -i metadata.yaml -o mapped_output -d out_dbsnp \\"
 echo "                              --target-build GRCh37 --output-format minimal"
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
# Save original arguments
original_args=("$@")

# Check for command modifiers (first argument)
runtype="default"
command=""
if [ $# -gt 0 ]; then
  case "$1" in
    prepare-dbsnp)
      runtype="prepare-dbsnp"
      command="prepare-dbsnp"
      shift
      # Check if help is requested for this command
      if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
        prepare_dbsnp_usage
        exit 0
      fi
      ;;
    prepare-1kgp)
      runtype="prepare-1kgp"
      command="prepare-1kgp"
      shift
      # Check if help is requested for this command
      if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
        prepare_1kgp_usage
        exit 0
      fi
      ;;
    test)
      runtype="test"
      command="test"
      shift
      # Check if help is requested for this command
      if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
        test_usage
        exit 0
      fi
      ;;
    map-only)
      runtype="map-only"
      command="map-only"
      shift
      # Check if help is requested for this command
      if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
        map_only_usage
        exit 0
      fi
      ;;
  esac
fi

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

# Test-specific flags
run_unit_tests=false
run_e2e_tests=false
specific_test_name=""

# Map-only specific flags
target_build="both"
apply_mapping=false
keep_unmapped=false
output_format="minimal"

# default extrapaths values
unset extrapaths
unset extrapaths2

# default system tmp
tmpdir="/tmp"
workdir="${present_dir}/work"
devmode=""

# Parse both short and long options using the common portable pattern
while [ $# -gt 0 ]; do
  case "$1" in
    # Long options
    --help)
      general_usage 1>&2
      exit 0
      ;;
    --version)
      cat ${project_dir}/VERSION 1>&2
      exit 0
      ;;
    --input)
      infile="$2"
      infile_given=true
      shift 2
      ;;
    --input=*)
      infile="${1#*=}"
      infile_given=true
      shift
      ;;
    --output)
      outdir="$2"
      outdir_given=true
      shift 2
      ;;
    --output=*)
      outdir="${1#*=}"
      outdir_given=true
      shift
      ;;
    --dbsnp)
      dbsnpdir="$2"
      dbsnpdir_given=true
      shift 2
      ;;
    --dbsnp=*)
      dbsnpdir="${1#*=}"
      dbsnpdir_given=true
      shift
      ;;
    --1kgp|--kgp)
      kgpdir="$2"
      kgpdir_given=true
      shift 2
      ;;
    --1kgp=*|--kgp=*)
      kgpdir="${1#*=}"
      kgpdir_given=true
      shift
      ;;
    --tmpdir)
      tmpdir="$2"
      tmpdir_given=true
      shift 2
      ;;
    --tmpdir=*)
      tmpdir="${1#*=}"
      tmpdir_given=true
      shift
      ;;
    --workdir)
      workdir="$2"
      workdir_given=true
      shift 2
      ;;
    --workdir=*)
      workdir="${1#*=}"
      workdir_given=true
      shift
      ;;
    --paths)
      extrapaths="$2"
      extrapaths_given=true
      shift 2
      ;;
    --paths=*)
      extrapaths="${1#*=}"
      extrapaths_given=true
      shift
      ;;
    --example)
      if [ -n "$2" ] && [[ "$2" != -* ]]; then
        runexampledatanr="$2"
        shift 2
      else
        runexampledatanr="1"
        shift
      fi
      runexampledata=true
      ;;
    --example=*)
      runexampledatanr="${1#*=}"
      runexampledata=true
      shift
      ;;
    --dev)
      devmode="--dev"
      devmode_given=true
      shift
      ;;
    --image|--container)
      container_image="$2"
      container_image_given=true
      shift 2
      ;;
    --image=*|--container=*)
      container_image="${1#*=}"
      container_image_given=true
      shift
      ;;
    --test)
      pathquicktest=true
      shift
      ;;
    --unit)
      run_unit_tests=true
      shift
      ;;
    --e2e)
      run_e2e_tests=true
      shift
      ;;
    --name)
      # Specific test name (only valid with test command)
      if [ "$command" = "test" ]; then
        specific_test_name="$2"
        shift 2
      else
        echo "Error: --name flag is only valid with 'test' command" 1>&2
        exit 1
      fi
      ;;
    --target-build)
      target_build="$2"
      shift 2
      ;;
    --target-build=*)
      target_build="${1#*=}"
      shift
      ;;
    --apply-mapping)
      apply_mapping=true
      shift
      ;;
    --keep-unmapped)
      keep_unmapped=true
      shift
      ;;
    --output-format)
      output_format="$2"
      shift 2
      ;;
    --output-format=*)
      output_format="${1#*=}"
      shift
      ;;
    
    # Short options
    -h)
      # Show command-specific help if in a command context
      if [ "$command" = "test" ]; then
        test_usage 1>&2
      elif [ "$command" = "prepare-dbsnp" ]; then
        prepare_dbsnp_usage 1>&2
      elif [ "$command" = "prepare-1kgp" ]; then
        prepare_1kgp_usage 1>&2
      elif [ "$command" = "map-only" ]; then
        map_only_usage 1>&2
      else
        general_usage 1>&2
      fi
      exit 0
      ;;
    -v)
      cat ${project_dir}/VERSION 1>&2
      exit 0
      ;;
    -u)
      # Unit test flag (only valid with test command)
      if [ "$command" = "test" ]; then
        run_unit_tests=true
      else
        echo "Error: -u flag is only valid with 'test' command" 1>&2
        exit 1
      fi
      shift
      ;;
    -i)
      infile="$2"
      infile_given=true
      shift 2
      ;;
    -o)
      outdir="$2"
      outdir_given=true
      shift 2
      ;;
    -d)
      dbsnpdir="$2"
      dbsnpdir_given=true
      shift 2
      ;;
    -k)
      kgpdir="$2"
      kgpdir_given=true
      shift 2
      ;;
    -b)
      tmpdir="$2"
      tmpdir_given=true
      shift 2
      ;;
    -w)
      workdir="$2"
      workdir_given=true
      shift 2
      ;;
    -p)
      extrapaths="$2"
      extrapaths_given=true
      shift 2
      ;;
    -n)
      # Specific test name (only valid with test command)
      if [ "$command" = "test" ]; then
        specific_test_name="$2"
        shift 2
      else
        echo "Error: -n flag is only valid with 'test' command" 1>&2
        exit 1
      fi
      ;;
    -e)
      # Check if this is for e2e tests (with test command) or example data
      if [ "$command" = "test" ]; then
        run_e2e_tests=true
        shift
      else
        # Original behavior for example data
        if [ -n "$2" ] && [[ "$2" != -* ]]; then
          runexampledatanr="$2"
          shift 2
        else
          runexampledatanr="1"
          shift
        fi
        runexampledata=true
      fi
      ;;
    -l)
      devmode="--dev"
      devmode_given=true
      shift
      ;;
    -j)
      container_image="$2"
      container_image_given=true
      shift 2
      ;;
    -t)
      pathquicktest=true
      shift
      ;;
    
    # Handle combined short options (e.g., -vt)
    -[^-]*)
      # Split combined options
      opts="${1#-}"
      shift
      while [ -n "$opts" ]; do
        opt="${opts:0:1}"
        opts="${opts:1}"
        case "$opt" in
          h)
            general_usage 1>&2
            exit 0
            ;;
          v)
            cat ${project_dir}/VERSION 1>&2
            exit 0
            ;;
          t)
            pathquicktest=true
            ;;
          l)
            devmode="--dev"
            devmode_given=true
            ;;
          e)
            # Check context for e flag
            if [ "$command" = "test" ]; then
              run_e2e_tests=true
            else
              runexampledata=true
              runexampledatanr="1"
            fi
            ;;
          u)
            # Unit test flag
            if [ "$command" = "test" ]; then
              run_unit_tests=true
            else
              echo "Invalid Option: -u (only valid with 'test' command)" 1>&2
              exit 1
            fi
            ;;
          *)
            echo "Invalid Option: -$opt" 1>&2
            exit 1
            ;;
        esac
      done
      ;;
    
    # Error handling
    -*)
      echo "Invalid Option: $1" 1>&2
      exit 1
      ;;
    *)
      # Non-option argument
      echo "Unexpected argument: $1" 1>&2
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
elif [ "${runtype}" == "test" ]; then
  # All are placeholders and not used
  infile="${project_dir}/VERSION"
  outdir="${outdir}"
  dbsnpdir="${outdir}"
  kgpdir="${outdir}"
  
  # Determine which test type to run based on flags
  if ${run_unit_tests} && ${run_e2e_tests}; then
    # Both flags set, run all tests (default behavior)
    :
  elif ${run_unit_tests}; then
    # Override runtype to run unit tests only
    runtype="utest"
  elif ${run_e2e_tests}; then
    # Override runtype to run e2e tests only
    runtype="etest"
  fi
  # If neither flag is set, runtype remains "test" (run all tests)
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
elif [ "${runtype}" == "map-only" ]; then
  run_script="/cleansumstats/main.nf"
  # Add map-only specific parameters to the nextflow run command
  map_only_params="--mapping_only true --targetGenomeBuild ${target_build} --mappingOutputFormat ${output_format}"
  if [ "${apply_mapping}" = true ]; then
    map_only_params="${map_only_params} --applyMapping"
  fi
  if [ "${keep_unmapped}" = true ]; then
    map_only_params="${map_only_params} --keepUnmapped"
  fi
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
    # Add specific test name if provided
    if [ -n "${specific_test_name}" ] && [ "${runtype}" == "etest" ]; then
      exec docker run --rm ${mount_flags} "${runimage}" ${run_script} "${specific_test_name}"
    else
      exec docker run --rm ${mount_flags} "${runimage}" ${run_script}
    fi
  elif [ "${container_image}" == "docker" ]; then
    echo "container: $runimage"
    mount_flags=$(format_mount_flags "-v")
    # Add specific test name if provided
    if [ -n "${specific_test_name}" ] && [ "${runtype}" == "etest" ]; then
      exec docker run --rm ${mount_flags} "${runimage}" ${run_script} "${specific_test_name}"
    else
      exec docker run --rm ${mount_flags} "${runimage}" ${run_script}
    fi
  else
    echo "container: $runimage"
    mount_flags=$(format_mount_flags "-B")
    # Add specific test name if provided
    if [ -n "${specific_test_name}" ] && [ "${runtype}" == "etest" ]; then
      singularity exec \
         --cleanenv \
         ${mount_flags} \
         "${runimage}" \
         ${run_script} "${specific_test_name}"
    else
      singularity exec \
         --cleanenv \
         ${mount_flags} \
         "${runimage}" \
         ${run_script}
    fi
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
       --kg1000AFGRCh38 "${kgpfile_container}" \
       ${map_only_params:-}
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
       --kg1000AFGRCh38 "${kgpfile_container}" \
       ${map_only_params:-}
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
       --kg1000AFGRCh38 "${kgpfile_container}" \
       ${map_only_params:-}
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

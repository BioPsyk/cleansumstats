indir=$1
suffix="$2"

indir_host=$(realpath "${indir}")

# Test that file and folder exists, all of these will always get mounted
if [ ! -d $indir_host ]; then
  >&2 echo "indir doesn't exist"
  exit 1
fi


# All paths we see will start from the project root, even if the command is called from somewhere else
project_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${project_dir}/scripts/init-containerization.sh"

mount_flags=$(format_mount_flags "-B")

# indir
indir_container="/cleansumstats/input"

# outdir
#outdir_host=$(dirname "${outfile_host}")
#outfile_name=$(basename "${outfile_host}")
#outdir_container="/cleansumstats/outdir"
#outfile_container="${outdir_container}/${outfile_name}"

FAKE_HOME="tmp/fake-home"
export SINGULARITY_HOME="/cleansumstats/${FAKE_HOME}"
mkdir -p "${FAKE_HOME}"

#echo      "${infile_container}" 
#echo      "${outfile_container}"

exec singularity run \
   --contain \
   --cleanenv \
   ${mount_flags} \
   -B "${indir_host}:${indir_container}" \
   -B "/tmp:/tmp" \
   "tmp/${singularity_image_tag}" \
   /cleansumstats/bin/table_from_sumstat_library.sh \
     "${indir_container}" \
     "${suffix}"


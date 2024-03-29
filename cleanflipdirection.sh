infile=$1
outfile=$2

infile_host=$(realpath "${infile}")
outfile_host=$(realpath "${outfile}")

# Test that file and folder exists, all of these will always get mounted
if [ ! -f $infile_host ]; then
  >&2 echo "infile doesn't exist"
  exit 1
fi


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
outdir_host=$(dirname "${outfile_host}")
outfile_name=$(basename "${outfile_host}")
outdir_container="/cleansumstats/outdir"
outfile_container="${outdir_container}/${outfile_name}"

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
   -B "${outdir_host}:${outdir_container}" \
   -B "/tmp:/tmp" \
   "tmp/${singularity_image_tag}" \
   /cleansumstats/bin/flip_direction_on_clean.sh \
     "${infile_container}" \
     "${outfile_container}"


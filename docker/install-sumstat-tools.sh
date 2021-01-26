#!/usr/bin/env bash

set -e

if [ -z "${1}" ]; then
  echo "[ERROR] Binary directory of sumstat-tools not given as first argument"
  exit 1
fi

if [ -z "${2}" ]; then
  echo "[ERROR] Binary directory of distribution not given as second argument"
  exit 1
fi

sumstat_tools_bin_dir="${1}"
distribution_bin_dir="${2}"

for binary_path in "${sumstat_tools_bin_dir}"/*
do
  binary_name=$(basename "${binary_path}")

  echo ">> Installing ${binary_name}"

  cat <<EOF > "${distribution_bin_dir}/${binary_name}"
#!/usr/bin/env bash

exec bash "${binary_path}" "\$@"
EOF

  chmod +x "${distribution_bin_dir}/${binary_name}"
done

echo "-- All binaries installed"

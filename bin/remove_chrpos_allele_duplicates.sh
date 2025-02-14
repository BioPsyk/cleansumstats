#!/usr/bin/env bash

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

# Get input/output files from arguments
input_file=$1
output_unique=$2
output_removed=$3

# Define temporary files in current directory
temp_keys="duplicate_keys.txt"
temp_composite="composite_keys.txt"

# Copy header to both output files
head -n1 "${input_file}" > "${output_unique}"
head -n1 "${input_file}" > "${output_removed}"

# First pass: Create composite keys and find duplicates
awk -F'\t' 'NR>1 {print $2 ":" $4 ":" $5}' "${input_file}" > "${temp_composite}"

# Find duplicate keys
sort "${temp_composite}" | uniq -d > "${temp_keys}"

# If there are no duplicates, just copy all data rows to unique file
if [ ! -s "${temp_keys}" ]; then
    awk -F'\t' 'NR>1' "${input_file}" >> "${output_unique}"
    rm -f "${temp_keys}" "${temp_composite}"
    exit 0
fi

# Second pass: Separate records into unique and duplicate files
awk -F'\t' -v dup_file="${temp_keys}" \
           -v out_unique="${output_unique}" \
           -v out_removed="${output_removed}" '
BEGIN {
    # Read duplicate keys into array
    while ((getline key < dup_file) > 0) {
        dup_keys[key] = 1
    }
}
NR>1 {
    # Create composite key
    key = $2 ":" $4 ":" $5
    
    # Output to appropriate file based on whether key is in duplicates
    if (key in dup_keys) {
        print >> out_removed
    } else {
        print >> out_unique
    }
}' "${input_file}"

# Clean up temporary files
rm -f "${temp_keys}" "${temp_composite}" 
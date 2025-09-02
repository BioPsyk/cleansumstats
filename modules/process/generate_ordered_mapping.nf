process generate_ordered_mapping {
  tag "$mID"
  memory '2 GB'
  publishDir "${params.outdir}", mode: 'copy', enabled: params.applyMapping
  
  input:
  tuple val(mID), path(sumstats), path(mapped), path(unmapped)
  
  output:
  tuple val(mID), path("mapping_results.tsv.gz"), emit: ordered_mapping
  
  script:
  """
  #!/bin/bash
  set -euo pipefail
  
  # Function to handle both gzipped and non-gzipped files
  catfile() {
    if [[ \$1 == *.gz ]]; then
      zcat "\$1"
    else
      cat "\$1"
    fi
  }
  
  # Create header for output file
  echo -e "row_index\tmapping_status\trsid_mapped\tchrpos_GRCh38\tchrpos_GRCh37" > mapping_results.tsv
  
  # Get total number of rows (excluding header)
  # Use awk to count lines properly even if last line lacks newline
  total_rows=\$(catfile ${sumstats} | tail -n +2 | awk 'END {print NR}')
  echo "DEBUG: Total rows: \$total_rows" >&2
  
  # Create associative arrays for mapped variants
  declare -A mapped_rsids
  declare -A mapped_chrpos38
  declare -A mapped_chrpos37
  
  # Read mapped variants (assumes format: row_index, CHRPOS, RSID, A1, A2)
  while IFS=\$'\t' read -r idx chrpos rsid a1 a2; do
    if [[ "\$idx" != "0" ]] && [[ "\$idx" =~ ^[0-9]+\$ ]]; then
      mapped_rsids[\$idx]="\$rsid"
      # For now, use same chrpos for both builds (should be split in real implementation)
      mapped_chrpos38[\$idx]="\$chrpos"
      mapped_chrpos37[\$idx]="\$chrpos"
      echo "DEBUG: Mapped row \$idx -> \$rsid" >&2
    fi
  done < <(catfile ${mapped})
  
  echo "DEBUG: Total mapped entries: \${#mapped_rsids[@]}" >&2
  
  # Generate output for each row in original order
  for i in \$(seq 1 \$total_rows); do
    if [[ -n "\${mapped_rsids[\$i]:-}" ]]; then
      # This variant was mapped
      echo -e "\$i\tmapped\t\${mapped_rsids[\$i]}\t\${mapped_chrpos38[\$i]}\t\${mapped_chrpos37[\$i]}"
    else
      # This variant was not mapped
      echo -e "\$i\tunmapped\t.\t.\t."
    fi
  done >> mapping_results.tsv
  
  echo "DEBUG: Generated \$(wc -l < mapping_results.tsv) lines" >&2
  
  # Compress the output
  gzip mapping_results.tsv
  """
}
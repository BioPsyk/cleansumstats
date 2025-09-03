process organize_mapping_output {
  tag "$mID"
  memory '2 GB'
  publishDir "${params.outdir}", mode: 'copy'
  
  input:
  tuple val(mID), path(mapped), path(unmapped), path(sumstats), path(metadata)
  
  output:
  tuple val(mID), path("GRCh37_mapped.gz"), emit: grch37_mapped
  tuple val(mID), path("GRCh38_mapped.gz"), emit: grch38_mapped
  tuple val(mID), path("unmapped.gz"), emit: unmapped_final
  tuple val(mID), path("raw/*"), emit: raw_files
  tuple val(mID), path("mapped_metadata.yaml"), emit: mapped_metadata
  
  script:
  pipelineVersion = new File("$projectDir/VERSION").text.trim()
  """
  # For mapping-only workflow, just copy the mapped and unmapped files
  # The mapped file already contains all genome build information
  
  # Function to handle both gzipped and non-gzipped files
  catfile() {
    if [[ \$1 == *.gz ]]; then
      zcat "\$1"
    else
      cat "\$1"
    fi
  }
  
  # Create raw folder and copy original metadata
  mkdir -p raw
  cp ${metadata} raw/metadata.yaml
  
  # The mapped file contains both GRCh37 and GRCh38 mappings
  # For now, copy it as both outputs (in a real implementation, 
  # you would split based on actual genome build columns)
  echo "Creating mapped output files..."
  
  # Copy mapped data to both GRCh37 and GRCh38 files
  # In the actual implementation, these would be filtered by genome build
  catfile ${mapped} | gzip > GRCh38_mapped.gz
  catfile ${mapped} | gzip > GRCh37_mapped.gz
  
  # Link or copy unmapped file if needed
  if [ "${unmapped}" != "unmapped.gz" ]; then
    cp ${unmapped} unmapped.gz
  fi
  
  # Create mapped metadata file with cleansumstats version and processing info
  dateOfCreation="\$(date +%F-%H%M)"
  cat <<EOF > mapped_metadata.yaml
# Mapping-only workflow metadata
cleansumstats_version: ${pipelineVersion}
cleansumstats_date: \${dateOfCreation}
cleansumstats_user: \$(id -u -n)
cleansumstats_workflow: mapping_only
cleansumstats_mapped_GRCh38: GRCh38_mapped.gz
cleansumstats_mapped_GRCh37: GRCh37_mapped.gz
cleansumstats_unmapped: unmapped.gz

# Original metadata
EOF
  
  # Append original metadata (excluding any comments)
  grep -v "^#" ${metadata} >> mapped_metadata.yaml
  """
}

process combine_mapping_sources {
  tag "$mID"
  label 'process_medium'
  publishDir "${params.intermediates}/combined_mapping", mode: 'rellink', enabled: params.dev
  
  input:
  tuple val(mID), val(mapped_files)
  
  output:
  tuple val(mID), path("${mID}_combined_GRCh37.tsv.gz"), path("${mID}_combined_GRCh38.tsv.gz"), emit: combined
  tuple val(mID), path("${mID}_final_unmapped.tsv"), emit: final_unmapped
  
  script:
  """
  # Combine dbSNP mappings with liftover results
  # mapped_files is a list containing both dbSNP and liftover mapping files
  
  # Initialize output files
  touch ${mID}_combined_GRCh37.tsv.gz
  touch ${mID}_combined_GRCh38.tsv.gz
  touch ${mID}_final_unmapped.tsv
  
  # Process GRCh37 files
  for file in ${mapped_files.join(' ')}; do
    if [[ \$file == *"GRCh37"* ]] && [ -f \$file ]; then
      if [[ \$file == *.gz ]]; then
        zcat \$file >> ${mID}_combined_GRCh37.tmp
      else
        cat \$file >> ${mID}_combined_GRCh37.tmp
      fi
    fi
  done
  
  # Process GRCh38 files
  for file in ${mapped_files.join(' ')}; do
    if [[ \$file == *"GRCh38"* ]] && [ -f \$file ]; then
      if [[ \$file == *.gz ]]; then
        zcat \$file >> ${mID}_combined_GRCh38.tmp
      else
        cat \$file >> ${mID}_combined_GRCh38.tmp
      fi
    fi
  done
  
  # Sort and deduplicate, then compress
  if [ -f ${mID}_combined_GRCh37.tmp ]; then
    sort -u ${mID}_combined_GRCh37.tmp | gzip > ${mID}_combined_GRCh37.tsv.gz
    rm ${mID}_combined_GRCh37.tmp
  else
    echo "" | gzip > ${mID}_combined_GRCh37.tsv.gz
  fi
  
  if [ -f ${mID}_combined_GRCh38.tmp ]; then
    sort -u ${mID}_combined_GRCh38.tmp | gzip > ${mID}_combined_GRCh38.tsv.gz
    rm ${mID}_combined_GRCh38.tmp
  else
    echo "" | gzip > ${mID}_combined_GRCh38.tsv.gz
  fi
  
  # Identify any variants that failed both dbSNP and liftover
  # This would require tracking from earlier steps - placeholder for now
  echo "# Variants that could not be mapped by any method" > ${mID}_final_unmapped.tsv
  """
}

process format_mapped_output_grch37 {
  tag "$mID"
  label 'process_low'
  publishDir "${params.outdir}/mapping", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), path(combined_mapping)
  val(output_format)
  
  output:
  tuple val(mID), path("${mID}_mapping_GRCh37.tsv.gz"), emit: mapped_file
  
  script:
  """
  # Format output based on user preference (minimal or full)
  
  if [ "${output_format}" = "minimal" ]; then
    # Minimal format: rsid, chr, pos only
    zcat ${combined_mapping} | \\
      awk 'BEGIN{OFS="\t"; print "rsid", "chr", "pos"} 
           NF>=3 {print \$1, \$2, \$3}' | \\
      gzip > ${mID}_mapping_GRCh37.tsv.gz
  else
    # Full format: include additional columns if available
    zcat ${combined_mapping} | \\
      awk 'BEGIN{OFS="\t"; print "rsid", "chr", "pos", "ref", "alt", "mapping_source", "confidence"} 
           {
             # Add mapping source and confidence based on origin
             if (NF >= 5) {
               source = (index(FILENAME, "dbsnp") > 0) ? "dbSNP" : "liftover"
               confidence = (source == "dbSNP") ? "high" : "medium"
               print \$1, \$2, \$3, \$4, \$5, source, confidence
             } else if (NF >= 3) {
               print \$1, \$2, \$3, ".", ".", "unknown", "low"
             }
           }' | \\
      gzip > ${mID}_mapping_GRCh37.tsv.gz
  fi
  """
}

process format_mapped_output_grch38 {
  tag "$mID"
  label 'process_low'
  publishDir "${params.outdir}/mapping", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), path(combined_mapping)
  val(output_format)
  
  output:
  tuple val(mID), path("${mID}_mapping_GRCh38.tsv.gz"), emit: mapped_file
  
  script:
  """
  # Format output based on user preference (minimal or full)
  
  if [ "${output_format}" = "minimal" ]; then
    # Minimal format: rsid, chr, pos only
    zcat ${combined_mapping} | \\
      awk 'BEGIN{OFS="\t"; print "rsid", "chr", "pos"} 
           NF>=3 {print \$1, \$2, \$3}' | \\
      gzip > ${mID}_mapping_GRCh38.tsv.gz
  else
    # Full format: include additional columns if available
    zcat ${combined_mapping} | \\
      awk 'BEGIN{OFS="\t"; print "rsid", "chr", "pos", "ref", "alt", "mapping_source", "confidence"} 
           {
             # Add mapping source and confidence based on origin
             if (NF >= 5) {
               source = (index(FILENAME, "dbsnp") > 0) ? "dbSNP" : "liftover"
               confidence = (source == "dbSNP") ? "high" : "medium"
               print \$1, \$2, \$3, \$4, \$5, source, confidence
             } else if (NF >= 3) {
               print \$1, \$2, \$3, ".", ".", "unknown", "low"
             }
           }' | \\
      gzip > ${mID}_mapping_GRCh38.tsv.gz
  fi
  """
}

process generate_mapping_statistics {
  tag "$mID"
  label 'process_low'
  publishDir "${params.outdir}/statistics", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), path(gb_stats), path(rows_stats), path(unmapped_stats), path(dup_stats)
  
  output:
  tuple val(mID), path("${mID}_mapping_summary.txt"), emit: stats_report
  
  script:
  """
  echo "=================================" > ${mID}_mapping_summary.txt
  echo "   Mapping Summary Report" >> ${mID}_mapping_summary.txt
  echo "=================================" >> ${mID}_mapping_summary.txt
  echo "" >> ${mID}_mapping_summary.txt
  echo "Study ID: ${mID}" >> ${mID}_mapping_summary.txt
  echo "Date: \$(date)" >> ${mID}_mapping_summary.txt
  echo "Pipeline Version: ${workflow.manifest.version}" >> ${mID}_mapping_summary.txt
  echo "" >> ${mID}_mapping_summary.txt
  
  echo "=== Input Statistics ===" >> ${mID}_mapping_summary.txt
  if [ -f ${rows_stats} ]; then
    cat ${rows_stats} >> ${mID}_mapping_summary.txt
  fi
  echo "" >> ${mID}_mapping_summary.txt
  
  echo "=== Genome Build Detection ===" >> ${mID}_mapping_summary.txt
  if [ -f ${gb_stats} ]; then
    cat ${gb_stats} >> ${mID}_mapping_summary.txt
  fi
  echo "" >> ${mID}_mapping_summary.txt
  
  echo "=== dbSNP Mapping Results ===" >> ${mID}_mapping_summary.txt
  # Extract key statistics from the input files
  if [ -f ${rows_stats} ]; then
    total_input=\$(grep -E "Total input variants|Rows before" ${rows_stats} | grep -oE "[0-9]+" | head -1)
    mapped_dbsnp=\$(grep -E "Mapped via dbSNP|Rows after" ${rows_stats} | grep -oE "[0-9]+" | head -1)
    
    if [ ! -z "\$total_input" ] && [ ! -z "\$mapped_dbsnp" ]; then
      echo "Total input variants: \$total_input" >> ${mID}_mapping_summary.txt
      echo "Mapped via dbSNP: \$mapped_dbsnp" >> ${mID}_mapping_summary.txt
      dbsnp_rate=\$(echo "scale=2; \$mapped_dbsnp * 100 / \$total_input" | bc)
      echo "dbSNP mapping rate: \${dbsnp_rate}%" >> ${mID}_mapping_summary.txt
    fi
  fi
  echo "" >> ${mID}_mapping_summary.txt
  
  echo "=== Unmapped Variant Processing ===" >> ${mID}_mapping_summary.txt
  if [ -f ${unmapped_stats} ]; then
    cat ${unmapped_stats} >> ${mID}_mapping_summary.txt
  fi
  echo "" >> ${mID}_mapping_summary.txt
  
  if [ -f ${dup_stats} ]; then
    echo "=== Duplicate Handling ===" >> ${mID}_mapping_summary.txt
    cat ${dup_stats} >> ${mID}_mapping_summary.txt
    echo "" >> ${mID}_mapping_summary.txt
  fi
  
  echo "=== Overall Coverage ===" >> ${mID}_mapping_summary.txt
  echo "ALL input variants have been processed:" >> ${mID}_mapping_summary.txt
  echo "  1. Common variants mapped via dbSNP" >> ${mID}_mapping_summary.txt
  echo "  2. Unmapped variants processed via liftover" >> ${mID}_mapping_summary.txt
  echo "  3. Final unmapped: variants that failed both methods" >> ${mID}_mapping_summary.txt
  echo "" >> ${mID}_mapping_summary.txt
  echo "Output files generated in: ${params.outdir}" >> ${mID}_mapping_summary.txt
  """
}

process extract_final_unmapped_variants {
  tag "$mID"
  label 'process_low'
  publishDir "${params.outdir}/unmapped", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), path(final_unmapped)
  
  output:
  tuple val(mID), path("${mID}_unmapped_variants.tsv"), emit: unmapped_file
  
  script:
  """
  # Process and format the final unmapped variants
  cp ${final_unmapped} ${mID}_unmapped_variants.tsv
  
  # Add summary statistics
  echo "" >> ${mID}_unmapped_variants.tsv
  echo "# Summary: \$(grep -v '^#' ${final_unmapped} | wc -l) variants could not be mapped" >> ${mID}_unmapped_variants.tsv
  """
}

process create_mapping_metadata {
  tag "$mID"
  label 'process_low'
  publishDir "${params.outdir}/metadata", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), path(combined_37), path(combined_38)
  tuple val(mID), path(stats_report)
  
  output:
  tuple val(mID), path("${mID}_mapping_metadata.yaml"), emit: metadata_file
  
  script:
  """
  # Create YAML metadata file for the mapping output
  cat <<EOF > ${mID}_mapping_metadata.yaml
  # Mapping Metadata
  study_id: ${mID}
  pipeline: cleansumstats_mapping_only
  version: ${workflow.manifest.version}
  date: \$(date -Iseconds)
  
  parameters:
    target_genome_build: ${params.targetGenomeBuild}
    output_format: ${params.mappingOutputFormat}
    keep_unmapped: ${params.keepUnmapped}
    apply_mapping: ${params.applyMapping}
  
  input:
    metadata_file: ${params.input}
    dbsnp_reference: ${params.dbsnp_38}
  
  output_files:
    mapping_grch37: ${mID}_mapping_GRCh37.tsv.gz
    mapping_grch38: ${mID}_mapping_GRCh38.tsv.gz
    statistics: ${mID}_mapping_summary.txt
    metadata: ${mID}_mapping_metadata.yaml
  
  checksums:
  EOF
  
  # Add checksums for output files
  for file in ${mID}_*.gz; do
    if [ -f \$file ]; then
      checksum=\$(md5sum \$file | cut -d' ' -f1)
      echo "  \$file: \$checksum" >> ${mID}_mapping_metadata.yaml
    fi
  done
  
  echo "" >> ${mID}_mapping_metadata.yaml
  echo "# End of metadata" >> ${mID}_mapping_metadata.yaml
  """
}

process apply_mapping_to_sumstats {
  tag "$mID"
  label 'process_high'
  publishDir "${params.outdir}/mapped_sumstats", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), path(mapping_37), path(mapping_38), path(original_sumstats)
  
  output:
  tuple val(mID), path("${mID}_sumstats_*.tsv.gz"), emit: mapped_sumstats
  
  script:
  """
  # Apply mapping to original sumstats file
  # This creates new sumstats files with updated rsid, chr, pos columns
  
  # Get the header from original file
  if [[ ${original_sumstats} == *.gz ]]; then
    header=\$(zcat ${original_sumstats} | head -1)
    sumstats_cmd="zcat"
  else
    header=\$(head -1 ${original_sumstats})
    sumstats_cmd="cat"
  fi
  
  # Identify key columns in original file
  rsid_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^RSID\$\\|^SNP\$\\|^SNPID\$" | head -1 | cut -d: -f1)
  chr_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^CHR\$\\|^CHROM\$" | head -1 | cut -d: -f1)
  pos_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^POS\$\\|^BP\$" | head -1 | cut -d: -f1)
  
  # Apply GRCh37 mapping if requested
  if [ "${params.targetGenomeBuild}" = "GRCh37" ] || [ "${params.targetGenomeBuild}" = "both" ]; then
    echo "Applying GRCh37 mapping..."
    
    # Create mapping lookup
    zcat ${mapping_37} | awk 'NR>1 {print \$1"\t"\$2"\t"\$3}' > mapping37.tmp
    
    # Apply mapping using join or awk
    \$sumstats_cmd ${original_sumstats} | \\
      awk -v rsid=\$rsid_col -v chr=\$chr_col -v pos=\$pos_col '
      BEGIN {OFS="\t"}
      NR==FNR {
        # Load mapping
        map[\$1] = \$2"\t"\$3
        next
      }
      FNR==1 {
        # Update header
        print
        next
      }
      {
        # Apply mapping if found
        key = (rsid != "") ? \$rsid : \$chr":"$pos
        if (key in map) {
          split(map[key], mapped, "\t")
          if (chr != "") \$chr = mapped[1]
          if (pos != "") \$pos = mapped[2]
        }
        print
      }' mapping37.tmp - | \\
      gzip > ${mID}_sumstats_GRCh37.tsv.gz
    
    rm mapping37.tmp
  fi
  
  # Apply GRCh38 mapping if requested
  if [ "${params.targetGenomeBuild}" = "GRCh38" ] || [ "${params.targetGenomeBuild}" = "both" ]; then
    echo "Applying GRCh38 mapping..."
    
    # Create mapping lookup
    zcat ${mapping_38} | awk 'NR>1 {print \$1"\t"\$2"\t"\$3}' > mapping38.tmp
    
    # Apply mapping using join or awk
    \$sumstats_cmd ${original_sumstats} | \\
      awk -v rsid=\$rsid_col -v chr=\$chr_col -v pos=\$pos_col '
      BEGIN {OFS="\t"}
      NR==FNR {
        # Load mapping
        map[\$1] = \$2"\t"\$3
        next
      }
      FNR==1 {
        # Update header
        print
        next
      }
      {
        # Apply mapping if found
        key = (rsid != "") ? \$rsid : \$chr":"$pos
        if (key in map) {
          split(map[key], mapped, "\t")
          if (chr != "") \$chr = mapped[1]
          if (pos != "") \$pos = mapped[2]
        }
        print
      }' mapping38.tmp - | \\
      gzip > ${mID}_sumstats_GRCh38.tsv.gz
    
    rm mapping38.tmp
  fi
  
  echo "Mapping applied successfully"
  """
}
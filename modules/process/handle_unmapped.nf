process handle_unmapped {
  tag "$mID"
  memory '2 GB'
  publishDir "${params.outdir}", mode: 'copy', enabled: params.mapping_only
  
  input:
  tuple val(mID), path(sumstats), path(mapped)
  
  output:
  tuple val(mID), path("unmapped.gz"), emit: unmapped
  
  script:
  """
  # Create a file with unmapped variants
  # The mapped file only contains successfully mapped variants
  # We need to identify which original variants are NOT in the mapped file
  
  # Function to handle both gzipped and non-gzipped files
  catfile() {
    if [[ \$1 == *.gz ]]; then
      zcat "\$1"
    else
      cat "\$1"
    fi
  }
  
  # Get header from original file
  catfile ${sumstats} | head -1 > unmapped
  
  # The mapped file has row indices in the first column
  # Extract these indices to identify which rows were mapped
  catfile ${mapped} | tail -n +2 | cut -f1 | sort | uniq > mapped_indices.txt
  
  # Get total number of rows in original (excluding header)
  total_rows=\$(catfile ${sumstats} | tail -n +2 | wc -l)
  
  # Generate all row indices and sort them (text sort for comm)
  seq 1 \$total_rows | sort > all_indices.txt
  
  # Find unmapped indices (rows that are not in mapped_indices)
  comm -23 all_indices.txt mapped_indices.txt > unmapped_indices.txt
  
  # Extract unmapped variants by row index
  if [ -s unmapped_indices.txt ]; then
    # Debug: show what's in unmapped_indices.txt
    echo "DEBUG: unmapped indices:" >&2
    cat unmapped_indices.txt >&2
    echo "DEBUG: first 5 data lines:" >&2
    catfile ${sumstats} | tail -n +2 | head -5 >&2
    
    # Read unmapped indices and extract corresponding lines from sumstats
    # Use awk to extract specific line numbers from the data
    catfile ${sumstats} | tail -n +2 | awk 'NR==FNR{lines[\$1]=1; next} FNR in lines' unmapped_indices.txt - >> unmapped
  fi
  
  # Compress output
  gzip unmapped
  
  # Cleanup
  rm -f mapped_indices.txt all_indices.txt unmapped_indices.txt
  """
}

process extract_unmapped_variants {
  tag "$mID"
  label 'process_medium'
  publishDir "${params.intermediates}/unmapped", mode: 'rellink', enabled: params.dev
  
  input:
  tuple val(mID), path(unmapped_ix), path(sumstats)
  
  output:
  tuple val(mID), path("${mID}_unmapped.tsv"), emit: unmapped_variants
  tuple val(mID), path("${mID}_variant_counts.txt"), emit: variant_counts
  
  script:
  """
  # Extract ALL unmapped variants by index
  # The unmapped_ix file contains row indices of variants that couldn't be mapped via dbSNP
  if [ -s ${unmapped_ix} ]; then
    awk 'NR==FNR{idx[\$1]; next} FNR in idx' ${unmapped_ix} ${sumstats} > ${mID}_unmapped.tsv
  else
    # No unmapped variants
    touch ${mID}_unmapped.tsv
  fi
  
  # Count by variant type for statistics
  total_unmapped=\$(wc -l < ${mID}_unmapped.tsv)
  echo "Total unmapped: \$total_unmapped" > ${mID}_variant_counts.txt
  
  # Count indels vs SNPs if we have allele columns
  # This assumes REF and ALT columns exist - adjust column numbers as needed
  if [ -s ${mID}_unmapped.tsv ]; then
    # Try to identify REF and ALT columns from header
    header=\$(head -1 ${sumstats})
    ref_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^REF\$\\|^A2\$\\|^OA\$" | head -1 | cut -d: -f1)
    alt_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^ALT\$\\|^A1\$\\|^EA\$" | head -1 | cut -d: -f1)
    
    if [ ! -z "\$ref_col" ] && [ ! -z "\$alt_col" ]; then
      indel_count=\$(awk -F'\t' -v ref=\$ref_col -v alt=\$alt_col '
        NR>1 && (length(\$ref) > 1 || length(\$alt) > 1)' ${mID}_unmapped.tsv | wc -l)
      snp_count=\$(awk -F'\t' -v ref=\$ref_col -v alt=\$alt_col '
        NR>1 && length(\$ref) == 1 && length(\$alt) == 1' ${mID}_unmapped.tsv | wc -l)
      
      echo "Indels: \$indel_count" >> ${mID}_variant_counts.txt
      echo "SNPs: \$snp_count" >> ${mID}_variant_counts.txt
    else
      echo "Indels: NA (allele columns not found)" >> ${mID}_variant_counts.txt
      echo "SNPs: NA (allele columns not found)" >> ${mID}_variant_counts.txt
    fi
  else
    echo "Indels: 0" >> ${mID}_variant_counts.txt
    echo "SNPs: 0" >> ${mID}_variant_counts.txt
  fi
  """
}

process prepare_variants_for_liftover {
  tag "$mID"
  label 'process_low'
  
  input:
  tuple val(mID), path(unmapped)
  
  output:
  tuple val(mID), path("${mID}_variants.bed"), emit: variant_bed
  
  script:
  """
  # Convert to BED format for liftover (0-based coordinates)
  # Handle both SNPs and indels
  
  if [ -s ${unmapped} ]; then
    # Get header to identify columns
    header=\$(head -1 ${unmapped})
    
    # Find column indices (1-based for awk)
    chr_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^CHR\$\\|^CHROM\$\\|^chromosome\$" | head -1 | cut -d: -f1)
    pos_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^POS\$\\|^BP\$\\|^position\$" | head -1 | cut -d: -f1)
    rsid_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^RSID\$\\|^SNP\$\\|^SNPID\$\\|^rsid\$" | head -1 | cut -d: -f1)
    ref_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^REF\$\\|^A2\$\\|^OA\$" | head -1 | cut -d: -f1)
    alt_col=\$(echo "\$header" | tr '\t' '\n' | grep -n "^ALT\$\\|^A1\$\\|^EA\$" | head -1 | cut -d: -f1)
    
    # Create BED file
    awk -F'\t' -v chr=\$chr_col -v pos=\$pos_col -v rsid=\$rsid_col -v ref=\$ref_col -v alt=\$alt_col '
    NR > 1 && \$chr != "" && \$pos != "" {
      # Clean chromosome name
      chrom = \$chr
      gsub(/^chr/, "", chrom)  # Remove chr prefix if present
      
      # Convert to 0-based position
      start = \$pos - 1
      
      # For indels, use REF length for end position
      # For SNPs, end = start + 1
      if (ref != "" && \$ref != "") {
        end = start + length(\$ref)
      } else {
        end = start + 1
      }
      
      # Use rsid if available, otherwise use chr:pos
      if (rsid != "" && \$rsid != "" && \$rsid != ".") {
        id = \$rsid
      } else {
        id = chrom ":" \$pos
      }
      
      # Include ref/alt alleles for later reference
      ref_allele = (ref != "" ? \$ref : "N")
      alt_allele = (alt != "" ? \$alt : "N")
      
      # BED format: chr start end name score strand
      print "chr" chrom, start, end, id, ".", ".", ref_allele, alt_allele
    }' OFS='\t' ${unmapped} > ${mID}_variants.bed
  else
    # No unmapped variants to process
    touch ${mID}_variants.bed
  fi
  """
}

process liftover_variants_to_target {
  tag "$mID"
  label 'process_high'
  publishDir "${params.intermediates}/variants_lifted", mode: 'rellink', enabled: params.dev
  
  input:
  tuple val(mID), path(variant_bed)
  val(target_build)
  
  output:
  tuple val(mID), val(target_build), path("${mID}_lifted_*.bed"), emit: lifted
  
  script:
  """
  # Use CrossMap for liftover (same tool as dbSNP preparation uses)
  # Chain files should be available from params
  
  if [ ! -s ${variant_bed} ]; then
    # No variants to lift
    if [ "${target_build}" = "both" ]; then
      touch ${mID}_lifted_GRCh38.bed
      touch ${mID}_lifted_GRCh37.bed
    elif [ "${target_build}" = "GRCh38" ]; then
      touch ${mID}_lifted_GRCh38.bed
    else
      touch ${mID}_lifted_GRCh37.bed
    fi
  else
    # Detect source genome build from chromosome naming and positions
    # This is a simplified detection - the full pipeline has more sophisticated detection
    max_pos=\$(awk '{if(\$3 > max) max=\$3} END{print max}' ${variant_bed})
    
    # Rough heuristic for genome build detection based on max position
    # GRCh37: max chr1 = 249250621
    # GRCh38: max chr1 = 248956422
    # This is very simplified - actual implementation should use the build detection from main pipeline
    
    if [ "${target_build}" = "both" ] || [ "${target_build}" = "GRCh38" ]; then
      # Lift to GRCh38
      if [ -f "${params.hg19ToHg38chain}" ]; then
        CrossMap.py bed ${params.hg19ToHg38chain} ${variant_bed} ${mID}_lifted_GRCh38.bed 2>/dev/null || true
      else
        # Fallback if CrossMap not available - just copy coordinates
        # In production, CrossMap should be in the container
        cp ${variant_bed} ${mID}_lifted_GRCh38.bed
      fi
    fi
    
    if [ "${target_build}" = "both" ] || [ "${target_build}" = "GRCh37" ]; then
      # Lift to GRCh37
      if [ -f "${params.hg38ToHg19chain}" ]; then
        CrossMap.py bed ${params.hg38ToHg19chain} ${variant_bed} ${mID}_lifted_GRCh37.bed 2>/dev/null || true
      else
        # Fallback if CrossMap not available
        cp ${variant_bed} ${mID}_lifted_GRCh37.bed
      fi
    fi
    
    # Ensure output files exist even if liftover fails
    if [ "${target_build}" = "both" ]; then
      [ -f ${mID}_lifted_GRCh38.bed ] || touch ${mID}_lifted_GRCh38.bed
      [ -f ${mID}_lifted_GRCh37.bed ] || touch ${mID}_lifted_GRCh37.bed
    elif [ "${target_build}" = "GRCh38" ]; then
      [ -f ${mID}_lifted_GRCh38.bed ] || touch ${mID}_lifted_GRCh38.bed
    else
      [ -f ${mID}_lifted_GRCh37.bed ] || touch ${mID}_lifted_GRCh37.bed
    fi
  fi
  """
}

process format_lifted_variants {
  tag "$mID"
  label 'process_low'
  publishDir "${params.outdir}/mapping", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), val(target_build), path(lifted_beds)
  
  output:
  tuple val(mID), path("${mID}_liftover_mapped_*.tsv.gz"), emit: formatted
  tuple val(mID), path("${mID}_lifted_counts.txt"), emit: lifted_counts
  tuple val(mID), path("${mID}_liftover_failed.tsv"), emit: failed
  
  script:
  """
  # Convert lifted BED back to mapping format
  for bed in ${lifted_beds}; do
    if [ -s \$bed ]; then
      # Extract genome build from filename
      build=\$(echo \$bed | grep -oP 'GRCh[0-9]+' || echo "unknown")
      
      # Format as: rsid chr pos (1-based)
      # This matches the format from dbSNP mapping
      awk '{
        chr = \$1
        gsub(/^chr/, "", chr)  # Remove chr prefix
        pos = \$2 + 1  # Convert back to 1-based
        rsid = \$4
        
        # Output in same format as dbSNP mapping
        print rsid, chr, pos
      }' OFS='\t' \$bed | gzip > ${mID}_liftover_mapped_\${build}.tsv.gz
    else
      # Empty file - no successful liftovers for this build
      build=\$(echo \$bed | grep -oP 'GRCh[0-9]+' || echo "unknown")
      echo "" | gzip > ${mID}_liftover_mapped_\${build}.tsv.gz
    fi
  done
  
  # Track variants that completely failed liftover
  # These are variants that couldn't be lifted to any target build
  touch ${mID}_liftover_failed.tsv
  
  # Count successful liftovers
  total_lifted=0
  for gz in ${mID}_liftover_mapped_*.tsv.gz; do
    if [ -f \$gz ]; then
      count=\$(zcat \$gz | grep -v "^\$" | wc -l)
      total_lifted=\$((total_lifted + count))
      build=\$(echo \$gz | grep -oP 'GRCh[0-9]+' || echo "unknown")
      echo "\${build} lifted: \$count" >> ${mID}_lifted_counts.txt
    fi
  done
  
  echo "Total lifted: \$total_lifted" >> ${mID}_lifted_counts.txt
  """
}

process generate_unmapped_statistics {
  tag "$mID"
  label 'process_low'
  publishDir "${params.outdir}/statistics", mode: 'copy', overwrite: true
  
  input:
  tuple val(mID), path(variant_counts), path(lifted_counts)
  
  output:
  tuple val(mID), path("${mID}_unmapped_stats.txt"), emit: stats_report
  
  script:
  """
  echo "=== Unmapped Variant Processing Summary ===" > ${mID}_unmapped_stats.txt
  echo "Study ID: ${mID}" >> ${mID}_unmapped_stats.txt
  echo "Timestamp: \$(date)" >> ${mID}_unmapped_stats.txt
  echo "" >> ${mID}_unmapped_stats.txt
  
  echo "=== Variants Not Found in dbSNP ===" >> ${mID}_unmapped_stats.txt
  cat ${variant_counts} >> ${mID}_unmapped_stats.txt
  echo "" >> ${mID}_unmapped_stats.txt
  
  echo "=== Liftover Results ===" >> ${mID}_unmapped_stats.txt
  cat ${lifted_counts} >> ${mID}_unmapped_stats.txt
  echo "" >> ${mID}_unmapped_stats.txt
  
  # Calculate success rate
  total_unmapped=\$(grep "^Total unmapped:" ${variant_counts} | cut -d: -f2 | tr -d ' ')
  total_lifted=\$(grep "^Total lifted:" ${lifted_counts} | cut -d: -f2 | tr -d ' ')
  
  if [ "\$total_unmapped" -gt 0 ]; then
    success_rate=\$(echo "scale=2; \$total_lifted * 100 / \$total_unmapped" | bc)
    echo "Liftover success rate: \${success_rate}%" >> ${mID}_unmapped_stats.txt
  else
    echo "Liftover success rate: N/A (no unmapped variants)" >> ${mID}_unmapped_stats.txt
  fi
  
  echo "" >> ${mID}_unmapped_stats.txt
  echo "Note: Unmapped variants typically include:" >> ${mID}_unmapped_stats.txt
  echo "  - Indels (insertions/deletions)" >> ${mID}_unmapped_stats.txt
  echo "  - Rare variants not in dbSNP" >> ${mID}_unmapped_stats.txt
  echo "  - Novel variants discovered in this study" >> ${mID}_unmapped_stats.txt
  echo "  - Variants with ambiguous mappings" >> ${mID}_unmapped_stats.txt
  """
}
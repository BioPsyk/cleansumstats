nextflow.enable.dsl=2

include {
  organize_mapping_output as organize_mapping_output_process
} from '../process/organize_mapping_output.nf'

include {
  generate_ordered_mapping
} from '../process/generate_ordered_mapping.nf'

workflow organize_mapping_output {
  take:
  mapped_variants      // Channel: tuple(mID, path(mapped_file))
  unmapped_variants    // Channel: tuple(mID, path(unmapped_file))
  original_sumstats    // Channel: tuple(mID, path(sumstats_file))
  metadata_file        // Channel: tuple(mID, path(metadata_file))
  
  main:
  // Organize the mapping output files
  organize_mapping_output_process(
    mapped_variants
      .join(unmapped_variants, by: 0)
      .join(original_sumstats, by: 0)
      .join(metadata_file, by: 0)
  )
  
  // Generate ordered mapping output if applyMapping is enabled
  if (params.applyMapping) {
    generate_ordered_mapping(
      original_sumstats
        .join(mapped_variants, by: 0)
        .join(unmapped_variants, by: 0)
    )
  }
  
  emit:
  grch37_mapped = organize_mapping_output_process.out.grch37_mapped
  grch38_mapped = organize_mapping_output_process.out.grch38_mapped
  unmapped_final = organize_mapping_output_process.out.unmapped_final
  raw_files = organize_mapping_output_process.out.raw_files
  mapped_metadata = organize_mapping_output_process.out.mapped_metadata
  ordered_mapping = params.applyMapping ? generate_ordered_mapping.out.ordered_mapping : Channel.empty()
}

// Keep the complex workflow for future use
workflow organize_mapping_output_complex {
  take:
  mapped_data          // Channel: tuple(mID, list of mapped files from dbSNP and liftover)
  stats_data          // Channel: genome build statistics from dbSNP mapping
  rows_before_after   // Channel: mapping statistics from dbSNP
  unmapped_stats      // Channel: statistics from unmapped variant processing
  removed_duplicates  // Channel: duplicate records removed during dbSNP mapping
  original_sumstats   // Channel: original sumstats for apply-mapping option
  
  main:
  // First, combine mapping sources (dbSNP + liftover) into unified files
  combine_mapping_sources(mapped_data)
  
  // Split combined mappings by target genome build
  combine_mapping_sources.out.combined
    .branch { mID, grch37_file, grch38_file ->
      grch37: params.targetGenomeBuild in ['GRCh37', 'both'] && grch37_file.exists()
        return tuple(mID, grch37_file)
      grch38: params.targetGenomeBuild in ['GRCh38', 'both'] && grch38_file.exists()
        return tuple(mID, grch38_file)
    }
    .set { ch_mapped_by_build }
  
  // Format outputs based on target builds and output format preference
  if (params.targetGenomeBuild in ['GRCh37', 'both']) {
    format_mapped_output_grch37(
      ch_mapped_by_build.grch37,
      params.mappingOutputFormat
    )
  }
  
  if (params.targetGenomeBuild in ['GRCh38', 'both']) {
    format_mapped_output_grch38(
      ch_mapped_by_build.grch38,
      params.mappingOutputFormat
    )
  }
  
  // Generate comprehensive mapping statistics
  generate_mapping_statistics(
    stats_data
      .join(rows_before_after, by: 0)
      .join(unmapped_stats, by: 0)
      .join(removed_duplicates, by: 0, remainder: true)
  )
  
  // Extract variants that couldn't be mapped by either method
  if (params.keepUnmapped) {
    extract_final_unmapped_variants(
      combine_mapping_sources.out.final_unmapped
    )
  }
  
  // Create mapping-specific metadata
  create_mapping_metadata(
    combine_mapping_sources.out.combined,
    generate_mapping_statistics.out.stats_report
  )
  
  // Apply mapping to original sumstats if requested
  if (params.applyMapping) {
    apply_mapping_to_sumstats(
      combine_mapping_sources.out.combined
        .join(original_sumstats, by: 0)
    )
  }
  
  // Collect outputs based on configuration
  mapped_grch37 = params.targetGenomeBuild in ['GRCh37', 'both'] ? 
    format_mapped_output_grch37.out.mapped_file : 
    Channel.empty()
    
  mapped_grch38 = params.targetGenomeBuild in ['GRCh38', 'both'] ? 
    format_mapped_output_grch38.out.mapped_file : 
    Channel.empty()
    
  mapped_sumstats = params.applyMapping ? 
    apply_mapping_to_sumstats.out.mapped_sumstats : 
    Channel.empty()
  
  emit:
  mapped_grch37 = mapped_grch37
  mapped_grch38 = mapped_grch38
  mapping_stats = generate_mapping_statistics.out.stats_report
  mapping_metadata = create_mapping_metadata.out.metadata_file
  mapped_sumstats = mapped_sumstats
}
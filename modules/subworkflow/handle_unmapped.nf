nextflow.enable.dsl=2

include {
  handle_unmapped as handle_unmapped_process
} from '../process/handle_unmapped.nf'

workflow handle_unmapped {
  take:
  original_sumstats    // Channel: tuple(mID, path(sumstats_file))
  mapped_variants      // Channel: tuple(mID, path(mapped_file))
  
  main:
  // Identify and extract unmapped variants
  handle_unmapped_process(
    original_sumstats.join(mapped_variants, by: 0)
  )
  
  emit:
  unmapped = handle_unmapped_process.out.unmapped
}

workflow handle_unmapped_with_liftover {
  take:
  unmapped_indices     // Channel: tuple(mID, path(unmapped_ix_file))
  original_sumstats    // Channel: tuple(mID, path(sumstats_file))
  target_build         // Value: target genome build (GRCh37, GRCh38, or both)
  
  main:
  // Extract ALL unmapped variants (indels, rare SNPs, novel variants)
  // These are variants that couldn't be mapped via dbSNP
  extract_unmapped_variants(
    unmapped_indices.join(original_sumstats, by: 0)
  )
  
  // Prepare variants for liftover (format as BED for CrossMap)
  prepare_variants_for_liftover(
    extract_unmapped_variants.out.unmapped_variants
  )
  
  // Perform liftover based on detected genome build
  // This uses chain files to convert coordinates between builds
  liftover_variants_to_target(
    prepare_variants_for_liftover.out.variant_bed,
    target_build
  )
  
  // Format lifted variants to match mapping output format
  format_lifted_variants(
    liftover_variants_to_target.out.lifted
  )
  
  // Generate statistics about unmapped variants by type
  generate_unmapped_statistics(
    extract_unmapped_variants.out.variant_counts
      .join(format_lifted_variants.out.lifted_counts, by: 0)
  )
  
  emit:
  lifted_variants = format_lifted_variants.out.formatted
  unmapped_statistics = generate_unmapped_statistics.out.stats_report
  failed_liftover = format_lifted_variants.out.failed
}
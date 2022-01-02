// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  final_assembly
  prep_GRCh37_coord
} from '../process/organize_output.nf' 

workflow organize_output {

  take:
  allele_corrected
  cleaned_stats

  main:

  // final assembly
  allele_corrected
    .join(cleaned_stats, by: 0)
    .set{ ch_allele_corrected_and_outstats }
  final_assembly(ch_allele_corrected_and_outstats)
  prep_GRCh37_coord(final_assembly.out.cleaned_file)
  //Collect and place in corresponding stepwise order
//  ch_removed_not_possible_to_lift_over_for_combined_set_ix
//   .join(ch_removed_by_allele_filter_ix, by: 0)
//   .join(ch_stats_filtered_removed_ix, by: 0)
//   .set{ ch_collected_removed_lines }

}

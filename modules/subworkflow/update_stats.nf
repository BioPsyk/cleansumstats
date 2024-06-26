// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  numeric_filter_stats
  convert_neglogP
  force_eaf
  prep_af_stats
  add_af_stats
  infer_stats
  merge_inferred_data
  select_stats_for_output
  rename_stat_col_names
  flip_effects
} from '../process/update_stats.nf' 

workflow update_stats {

  take:
  input
  input2

  main:


  numeric_filter_stats(input)
  convert_neglogP(numeric_filter_stats.out.ch_stats_filtered_remain00)
  force_eaf(convert_neglogP.out.ch_convert_neglog10P)
  rename_stat_col_names(force_eaf.out.stats_forced_eaf)
  rename_stat_col_names.out.renamed_stat_col_names
    .join(input2, by: 0)
    .set { ch_to_flip }
  flip_effects(ch_to_flip)

  prep_af_stats(input2)
    flip_effects.out.stats_flipped
    .join(prep_af_stats.out.ch_prep_ref_allele_frequency, by: 0)
    .set { ch_add_ref_freq }
  add_af_stats(ch_add_ref_freq)

  //mix and run inference for 1kg-AF version and for a version without
  add_af_stats.out.ch_added_ref_allele_frequency_kg
    .mix(add_af_stats.out.ch_added_ref_allele_frequency_default)
    .set{ ch_stats_to_infer }
  infer_stats(ch_stats_to_infer)
  //branch the stats_genome_build
  ch_stats_selection_filter=infer_stats.out.ch_stats_selection.branch { key, value, file2 ->
                  g1kaf_stats_branch: value == "g1kaf_stats_branch"
                  default_stats_branch: value == "default_stats_branch"
                  }
  g1kaf_stats_branch=ch_stats_selection_filter.g1kaf_stats_branch
  default_stats_branch=ch_stats_selection_filter.default_stats_branch

  //combine the 1kg af branch and default branch for inferred information
  g1kaf_stats_branch
    .join(default_stats_branch, by: 0)
    .map { key, val1, file1, val2, file2 -> tuple(key, file1, file2) }
    .set{ ch_inferred_stats_combined }
 
  merge_inferred_data(ch_inferred_stats_combined)
  //ch_stats_selection_only_contains_inferred_variables
  merge_inferred_data.out.ch_combined_set_of_inferred_data
    .join(add_af_stats.out.ch_added_ref_allele_frequency_default, by: 0)
    .set{ ch_stats_selection2 }

  select_stats_for_output(ch_stats_selection2)

  numeric_filter_stats.out.ch_desc_filtered_stat_rows_with_non_numbers_BA
   .join(infer_stats.out.ch_desc_inferred_stats_if_inferred_BA, by: 0)
   .join(select_stats_for_output.out.ch_desc_from_inferred_to_joined_selection_BA, by: 0)
   .join(select_stats_for_output.out.ch_desc_from_sumstats_to_joined_selection_BA, by: 0)
  .set { nrows_before_after }

  // to emit
  select_stats_for_output.out.ch_stats_for_output.set { cleaned_stats }
  select_stats_for_output.out.ch_stats_for_output_selected_source.set { cleaned_stats_col_source }
  numeric_filter_stats.out.ch_stats_filtered_removed_ix.set { stats_rm_by_filter_ix }

  emit:
  cleaned_stats
    cleaned_stats_col_source
    stats_rm_by_filter_ix
    nrows_before_after
}


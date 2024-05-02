// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  prepare_dbsnp_mapping_for_rsid
  remove_duplicated_rsid_before_liftmap
  maplift_dbsnp_GRCh38_rsid
  is_chrpos_different_from_snp_and_assign_dID2
  reformat_chromosome_information
  detect_genome_build
  decide_genome_build
  build_warning
  rm_dup_chrpos_before_maplift
  maplift_dbsnp_GRCh38_chrpos
  select_chrpos_or_snpchrpos
  reformat_sumstat
  split_multiallelics_resort_rowindex
} from '../process/map_to_dbsnp.nf' 

workflow map_to_dbsnp {

  take:
  input

  main:
  input
  .map { mID, spath ->
    def metadata = params.sess.get_metadata(mID)
    def pointsToDifferent = !metadata.chrpos_points_to_snp()
    def CHRPOSexists = metadata.chrpos_exists()
    def SNPexists= metadata.col_SNP != null
    return tuple(mID, spath, CHRPOSexists, SNPexists, pointsToDifferent)
  }
  .set { ch_present_markers }

  // LIFTOVER BRANCH 1 - rsid mapping
  prepare_dbsnp_mapping_for_rsid(ch_present_markers)
  remove_duplicated_rsid_before_liftmap(prepare_dbsnp_mapping_for_rsid.out.ch_liftover_33)
  maplift_dbsnp_GRCh38_rsid(remove_duplicated_rsid_before_liftmap.out.ch_liftover_3333)

  // LIFTOVER BRANCH 2 - chrpos mapping
  // mix the snpchrpos (from markername column) with chrpos (from own columns)
  is_chrpos_different_from_snp_and_assign_dID2(ch_present_markers)
  is_chrpos_different_from_snp_and_assign_dID2.out
    .mix(prepare_dbsnp_mapping_for_rsid.out.ch_liftover_snpchrpos)
    .set{ ch_liftover_snpchrpos_chrpos_mixed }
  reformat_chromosome_information(ch_liftover_snpchrpos_chrpos_mixed)
  whichbuild = ['GRCh35', 'GRCh36', 'GRCh37', 'GRCh38']
  detect_genome_build(reformat_chromosome_information.out.ch_chromosome_fixed, whichbuild)
  ch_genome_build_stats_grouped = detect_genome_build.out.ch_genome_build_stats.groupTuple(by:[0,1],size:4)
  decide_genome_build(ch_genome_build_stats_grouped)
  reformat_chromosome_information.out.ch_rowsAfter_number_of_lines.join(decide_genome_build.out.ch_build_stats_for_failsafe, by: 0).set{ ch_failsafe }
  build_warning(ch_failsafe)

  ch_liftover_3=decide_genome_build.out.ch_known_genome_build.join(reformat_chromosome_information.out.ch_chromosome_fixed, by: [0,1])
  //rm_dup_chrpos_before_maplift(ch_liftover_3)
  maplift_dbsnp_GRCh38_chrpos(ch_liftover_3)
  //maplift_dbsnp_GRCh38_chrpos(rm_dup_chrpos_before_maplift.out.ch_liftover_333)
  ch_chrpos_snp_filter=maplift_dbsnp_GRCh38_chrpos.out.ch_liftover_44.branch { key, value, liftedGRCh38 ->
                  liftover_branch_markername_chrpos: value == "liftover_branch_markername_chrpos"
                  liftover_branch_chrpos: value == "liftover_branch_chrpos"
                  }
  ch_chrpos=ch_chrpos_snp_filter.liftover_branch_chrpos
  ch_snpchrpos=ch_chrpos_snp_filter.liftover_branch_markername_chrpos
  ch_chrpos
    .join(ch_snpchrpos, by: 0)
    .join(maplift_dbsnp_GRCh38_rsid.out.ch_liftover_rsid, by: 0)
    .join(input, by: 0)
    .set{ ch_combined_chrpos_snpchrpos_rsid }
  //ch_combined_chrpos_snpchrpos_rsid.view()
  select_chrpos_or_snpchrpos(ch_combined_chrpos_snpchrpos_rsid)
  //rm_dup_chrpos_allele_rows(select_chrpos_or_snpchrpos.out.ch_liftover_final)
  reformat_sumstat(select_chrpos_or_snpchrpos.out.ch_liftover_final)
  split_multiallelics_resort_rowindex(reformat_sumstat.out.ch_mapped_GRCh38)

  //branch the stats_genome_build
  ch_stats_genome_build_filter=decide_genome_build.out.ch_stats_genome_build_chrpos.branch { key, value, file ->
                  liftover_branch_markername_chrpos: value == "liftover_branch_markername_chrpos"
                  liftover_branch_chrpos: value == "liftover_branch_chrpos"
                  }
  ch_stats_chrpos_gb=ch_stats_genome_build_filter.liftover_branch_chrpos
  ch_stats_snpchrpos_gb=ch_stats_genome_build_filter.liftover_branch_markername_chrpos
  //combine the chrpos and snpchrpos channels for genome build
  ch_stats_chrpos_gb
    .join(ch_stats_snpchrpos_gb, by: 0)
    .map { key, val, file, val2, file2 -> tuple(key, file, file2) }
    .set{ ch_gb_stats_combined }


  //join desc_BA   
  select_chrpos_or_snpchrpos.out.ch_desc_combined_set_after_liftover
  .join(reformat_sumstat.out.ch_desc_keep_a_GRCh38_reference_BA, by: 0)
  .join(split_multiallelics_resort_rowindex.out.ch_desc_split_multi_allelics_and_sort_on_rowindex_BA, by: 0)
  .set { rows_before_after }
  //.join(rm_dup_chrpos_allele_rows.out.ch_desc_removed_duplicates_after_liftover, by: 0)

// //Some that now are part of the branched workflow. Unclear how to save the the stepwise branched workflow before after steps, but all info should be exported in channels.
// //  .combine(ch_desc_sex_chrom_formatting_BA, by: 0)
// //  .combine(ch_desc_prep_for_dbsnp_mapping_BA, by: 0)
// //  .combine(ch_removed_rows_before_liftover, by: 0)
// //  .combine(ch_desc_liftover_to_GRCh38_and_map_to_dbsnp_BA, by: 0)

  //output
  split_multiallelics_resort_rowindex.out.ch_allele_correction.set { dbsnp_mapped }
  select_chrpos_or_snpchrpos.out.ch_removed_not_possible_to_lift_over_for_combined_set_ix.set { dbsnp_rm_ix }

  emit: 
  dbsnp_mapped
  dbsnp_rm_ix
  rows_before_after
  ch_gb_stats_combined
}



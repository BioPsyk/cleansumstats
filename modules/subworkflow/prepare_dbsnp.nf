
// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  dbsnp_reference_convert_and_split
  dbsnp_reference_reformat
  dbsnp_reference_rm_indels
  dbsnp_reference_report_number_of_biallelic_multiallelics
  dbsnp_reference_merge_before_duplicate_filters_GRCh38
  dbsnp_reference_rm_dup_positions_GRCh38
  dbsnp_split_before_2nd_liftover
  dbsnp_reference_liftover_GRCh37
  dbsnp_reference_merge_before_duplicate_filters_GRCh37
  dbsnp_reference_rm_dup_positions_GRCh37
  dbsnp_reference_rm_liftover_remaining_ambigous_GRCh37
  dbsnp_split_before_3nd_liftover
  dbsnp_reference_liftover_GRCh36
  dbsnp_reference_liftover_GRCh35
  dbsnp_reference_merge_reference_library_GRCh3x_GRCh38
  dbsnp_reference_rm_duplicates_GRCh36_GRCh35
  dbsnp_reference_rm_liftover_remaining_ambigous_GRCh36_GRCh35
  dbsnp_reference_put_files_in_reference_library_RSID
  dbsnp_reference_put_files_in_reference_library_GRCh38
  dbsnp_reference_select_sort_and_put_files_in_reference_library_GRCh3x_GRCh38
  dbsnp_reference_put_files_in_reference_library_GRCh38_GRCh37
} from '../process/prepare_dbsnp.nf' 


workflow prepare_dbsnp_reference {

  take:
  input

  main:

  Channel
    .fromPath(input, type: 'file')
    .map { file -> tuple(file.baseName, file) }
    .set { ch_file }

  dbsnpsplits=10
  dbsnp_reference_convert_and_split(ch_file, "${dbsnpsplits}")

  dbsnp_reference_convert_and_split.out.dbsnp_split
    .flatten()
    .map { file -> tuple(file.baseName, file) }
    .set { ch_dbsnp_split2 }

  dbsnp_reference_reformat(ch_dbsnp_split2)
  dbsnp_reference_rm_indels(dbsnp_reference_reformat.out)

  dbsnp_reference_report_number_of_biallelic_multiallelics(dbsnp_reference_rm_indels.out)
  dbsnp_reference_merge_before_duplicate_filters_GRCh38(dbsnp_reference_rm_indels.out.map {key,val -> val }.collect())

  dbsnp_reference_rm_dup_positions_GRCh38(dbsnp_reference_merge_before_duplicate_filters_GRCh38.out).set { ch_rm_dup_positions_GRCh38 }
  dbsnp_split_before_2nd_liftover(ch_rm_dup_positions_GRCh38, "${dbsnpsplits}")
  dbsnp_split_before_2nd_liftover.out
    .flatten()
    .map { file -> tuple(file.baseName, file) }
    .set { ch_dbsnp_split4 }
  dbsnp_reference_liftover_GRCh37(ch_dbsnp_split4)
  dbsnp_reference_merge_before_duplicate_filters_GRCh37(dbsnp_reference_liftover_GRCh37.out.collect())
  dbsnp_reference_rm_dup_positions_GRCh37(dbsnp_reference_merge_before_duplicate_filters_GRCh37.out)
  dbsnp_reference_rm_liftover_remaining_ambigous_GRCh37(dbsnp_reference_rm_dup_positions_GRCh37.out)
  dbsnp_split_before_3nd_liftover(dbsnp_reference_rm_liftover_remaining_ambigous_GRCh37.out.main, "${dbsnpsplits}")
  dbsnp_split_before_3nd_liftover.out
    .flatten()
    .map { file -> tuple(file.baseName, file) }
    .set { ch_dbsnp_split6 }
  dbsnp_reference_liftover_GRCh36(ch_dbsnp_split6)
  dbsnp_reference_liftover_GRCh35(ch_dbsnp_split6)
  dbsnp_reference_liftover_GRCh35.out
    .mix(dbsnp_reference_liftover_GRCh36.out)
    .set{ ch_dbsnp_lifted_to_GRCh3x }
  ch_dbsnp_lifted_to_GRCh3x_grouped = ch_dbsnp_lifted_to_GRCh3x.groupTuple(by:0)
  dbsnp_reference_merge_reference_library_GRCh3x_GRCh38(ch_dbsnp_lifted_to_GRCh3x_grouped)
  dbsnp_reference_rm_duplicates_GRCh36_GRCh35(dbsnp_reference_merge_reference_library_GRCh3x_GRCh38.out)
  dbsnp_reference_rm_liftover_remaining_ambigous_GRCh36_GRCh35(dbsnp_reference_rm_duplicates_GRCh36_GRCh35.out.main)

  //// Write dbsnp to reference output
  dbsnp_reference_put_files_in_reference_library_RSID(dbsnp_reference_rm_dup_positions_GRCh38.out)
  dbsnp_reference_put_files_in_reference_library_GRCh38(dbsnp_reference_rm_dup_positions_GRCh38.out)

  dbsnp_reference_put_files_in_reference_library_GRCh38_GRCh37(dbsnp_reference_rm_liftover_remaining_ambigous_GRCh37.out.main)

  ch_dbsnp_rmd_ambig_positions_GRCh3x_grouped = dbsnp_reference_rm_liftover_remaining_ambigous_GRCh36_GRCh35.out.main.groupTuple(by:0)
  dbsnp_reference_select_sort_and_put_files_in_reference_library_GRCh3x_GRCh38(ch_dbsnp_rmd_ambig_positions_GRCh3x_grouped)
}


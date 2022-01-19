// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  final_assembly
  prep_GRCh37_coord
  collect_rmd_lines
  desc_rmd_lines_as_table
  gzip_outfiles
  calculate_checksum_on_sumstat_cleaned
  collect_and_prep_stepwise_readme
  prepare_cleaned_metadata_file
  add_cleaned_to_output
  add_raw_to_output
  add_details_to_output
} from '../process/organize_output.nf' 

workflow organize_output {

  take:
  allele_corrected
  cleaned_stats
  rmd_lines
  raw_sfile
  raw_sfile_index
  nrows_before_after
  ch_mfile_cleaned_x
  ch_to_write_to_filelibrary7
  ch_mfile_checkX
  ch_to_write_to_raw

  main:

  // final assembly
  allele_corrected
    .join(cleaned_stats, by: 0)
    .set{ ch_allele_corrected_and_outstats }
  final_assembly(ch_allele_corrected_and_outstats)
  prep_GRCh37_coord(final_assembly.out.cleaned_file)

  collect_rmd_lines(rmd_lines)
  desc_rmd_lines_as_table(collect_rmd_lines.out.ch_collected_removed_lines2)

  prep_GRCh37_coord.out.ch_cleaned_file
    .join(raw_sfile, by: 0)
    .join(raw_sfile_index, by: 0)
    .join(collect_rmd_lines.out.ch_collected_removed_lines2, by: 0)
    .set{ ch_to_write_to_filelibrary2 }
  //ch_to_write_to_filelibrary2.view()
  gzip_outfiles(ch_to_write_to_filelibrary2)

  gzip_outfiles.out.gz_to_write
   .join(gzip_outfiles.out.gz_rm_lines_to_write, by: 0)
   .set { to_calculate_checksum_gz }
   calculate_checksum_on_sumstat_cleaned(to_calculate_checksum_gz)

  nrows_before_after
   .join(final_assembly.out.ch_desc_final_merge_BA, by: 0)
   .set{ ch_collected_workflow_stepwise_stats }
  collect_and_prep_stepwise_readme(ch_collected_workflow_stepwise_stats)

  ch_mfile_cleaned_x
    .join(calculate_checksum_on_sumstat_cleaned.out.ch_cleaned_sumstat_checksums, by: 0)
    .join(gzip_outfiles.out.ch_cleaned_header, by: 0)
    .set { for_cleaned_metadata }

  prepare_cleaned_metadata_file(for_cleaned_metadata)

  gzip_outfiles.out.gz_to_write
   .join(prepare_cleaned_metadata_file.out.ch_mfile_cleaned_1, by: 0)
   .set { cleaned_output }

  ch_to_write_to_filelibrary7
   .join(collect_and_prep_stepwise_readme.out.ch_overview_workflow_steps, by: 0)
   .join(gzip_outfiles.out.gz_rm_lines_to_write, by: 0)
   .join(desc_rmd_lines_as_table.out.ch_removed_lines_table, by: 0)
   .set { details_output }

  ch_mfile_checkX
   .join(ch_to_write_to_raw, by: 0)
   .join(gzip_outfiles.out.ch_to_write_to_raw_library, by: 0)
   .set { raw_output }

  add_raw_to_output(raw_output)
  add_details_to_output(details_output)
  add_cleaned_to_output(cleaned_output)
}


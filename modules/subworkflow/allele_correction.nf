// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  allele_correction_A1_A2
  allele_correction_A1
  rm_dup_chrpos_rows_after_acor
} from '../process/allele_correction.nf' 

workflow allele_correction {

  take:
  input

  main:

    input
    .map { mID, build, mapped, sfile ->
      def metadata = params.sess.get_metadata(mID)
      A2exists="${metadata.col_OtherAllele ? true : false}"
      return(tuple(mID, build, mapped, sfile, A2exists))
    }.set { ch_present_A2 }

    //Create filter for when A2 exists or not
    ch_present_A2_br=ch_present_A2.branch { mID, build, mapped, sfile, A2exists ->
                    A2exists: A2exists == true
                    A2missing: A2exists == false
                    }

    //split the channels based on filter
    ch_A2_exists=ch_present_A2_br.A2exists
    ch_A2_missing=ch_present_A2_br.A2missing

    allele_correction_A1_A2(ch_A2_exists)
    allele_correction_A1(ch_A2_missing)

    //mix the A1_A2_both and A1_solo channels
    allele_correction_A1_A2.out.ch_A2_exists2
      .mix(allele_correction_A1.out.ch_A2_missing2)
      .set{ ch_allele_corrected_mix_X }
    rm_dup_chrpos_rows_after_acor(ch_allele_corrected_mix_X)

    allele_correction_A1_A2.out.ch_removed_by_allele_filter_ix1
      .mix(allele_correction_A1.out.ch_removed_by_allele_filter_ix2)
      .set{ removed_by_allele_filter_ix }

    allele_correction_A1_A2.out.ch_desc_filtered_allele_pairs_with_dbsnp_as_reference_A1A2_BA
      .mix(allele_correction_A1.out.ch_desc_filtered_allele_pairs_with_dbsnp_as_reference_A1_BA)
      .set{ desc_filt_allele_pairs_BA }

  //output
  rm_dup_chrpos_rows_after_acor.out.ch_allele_corrected_mix_Y.set { allele_corrected }
  emit:
  allele_corrected
  removed_by_allele_filter_ix
  desc_filt_allele_pairs_BA
}




// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  is_chrpos_different_from_snp_and_assign_dID2
  prepare_dbsnp_mapping_for_rsid
} from '../process/map_to_dbsnp.nf' 

workflow map_to_dbsnp {

  take:
  input
  sess

  main:
  input
  .map { mID, meta, spath ->
    def metadata = sess.get_metadata(mID)
    def pointsToDifferent = !metadata.chrpos_points_to_snp()
    def CHRPOSexists = metadata.chrpos_exists()
    def SNPexists= metadata.col_SNP != null
    return tuple(mID, meta, spath, pointsToDifferent, CHRPOSexists, SNPexists)
  }
  .set { ch_present_markers }

  is_chrpos_different_from_snp_and_assign_dID2(ch_present_markers)

  // RSID
 // prepare_dbsnp_mapping_for_rsid(ch_present_markers)

 // prepare_dbsnp_mapping_for_rsid.out.ch_liftover_33.set { tmpout }
 // emit:
 // tmpout

}



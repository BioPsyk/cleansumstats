// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

workflow main_mfile_values {

  take:
  input
  sess

  main:
  input
  .map { mID, fl ->
    def metadata = sess.get_metadata(mID)
    def col_SNP = metadata.col_SNP ?: "missing"
    return tuple(mID, fl, spath, rpath, pmid, pdfpath, supps)
  }
  .set { all }

 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, fl, spath) }.set { mfile_check_format }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, spath) }.set { spath }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, rpath) }.set { rpath }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, pmid) }.set { pmid }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, pmid, pdfpath, supps) }.set { pdfstuff }

  emit:
  mfile_check_format
  spath
  rpath
  pmid
  pdfstuff

}



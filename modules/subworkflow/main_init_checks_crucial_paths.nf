// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

//This was a process in DSL-1
workflow main_init_checks_crucial_paths {

  take:
  input
  sess

  main:
  input
  .map { mID, fl ->
    def metadata = sess.get_metadata(mID)
    def spath = metadata.path_sumStats
    def rpath= metadata.path_readMe == null ? "missing" : metadata.path_readMe
    def pmid= metadata.study_PMID
    def pdfpath= metadata.path_pdf == null ? "missing" : metadata.path_pdf
    def supps = metadata.path_supplementary.join(" ")
    return tuple(mID, fl, spath, rpath, pmid, pdfpath, supps)
  }
  .set { all }

 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, fl, spath) }.set { mfile_check_format }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, spath) }.set { spath }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, rpath) }.set { rpath }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, pmid) }.set { pmid }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID, pmid, pdfpath, supps) }.set { pdfstuff }
 all.map { mID, fl, spath, rpath, pmid, pdfpath, supps -> tuple(mID) }.set { mID }

  emit:
  mfile_check_format
  spath
  rpath
  pmid
  pdfstuff
  mID


}



  //  process does_chrpos_exist {

  //    input:
  //    val(datasetID)
  //    //val datasetID from ch_init_does_chrpos_exist

  //    output:
  //    tuple datasetID, env(CHRPOSexists),env(SNPexists),env(pointsToDifferent) into ch_present_markers
  //    //tuple datasetID, env(CHRPOSexists),env(SNPexists),env(pointsToDifferent) into ch_present_markers

  //    script:
  //    def metadata = session.get_metadata(datasetID)

  //    """
  //    pointsToDifferent=${!metadata.chrpos_points_to_snp()}
  //    CHRPOSexists=${metadata.chrpos_exists()}
  //    SNPexists=${metadata.col_SNP != null}
  //    """
  //  }
//
//   ch_present_markersX=ch_liftover1.join(ch_present_markers, by: 0)
//   ch_present_markersX.into { ch_present_markers_1; ch_present_markers_2 }
//

// LIFTOVER BRANCH 1 - rsid mapping
process prepare_dbsnp_mapping_for_rsid {
    publishDir "${params.outdir}/intermediates/prepare_dbsnp_mapping_for_rsid", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(sfile), val(chrposExists), val(snpExists), val(pointsToDifferentCols)

    output:
    tuple val(datasetID), path("prepare_dbsnp_mapping_for_rsid__db_maplift"), val(snpExists), emit: ch_liftover_33
    tuple val(datasetID), env(dID2), path("prepare_dbsnp_mapping_for_rsid__gb_lift2"), val(snpExists), emit: ch_liftover_snpchrpos

    script:
    def metadata = params.sess.get_metadata(datasetID)
    colSNP="${metadata.col_SNP ?: "missing"}"
    """
    dID2="liftover_branch_markername_chrpos"
    prepare_dbsnp_mapping_for_rsid.sh ${sfile} ${snpExists} prepare_dbsnp_mapping_for_rsid__db_maplift prepare_dbsnp_mapping_for_rsid__gb_lift2 ${colSNP}

    # Process before and after stats
    rowsBefore="\$(wc -l ${sfile} | awk '{print \$1-1}')"
    rowsAfter="\$(wc -l prepare_dbsnp_mapping_for_rsid__db_maplift | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tPrepare file for mapping to dbsnp by sorting the mapping index" > desc_prepare_format_for_dbsnp_mapping_BA.txt
    """
}

process remove_duplicated_rsid_before_liftmap {
    publishDir "${params.outdir}/intermediates/liftover_branch_markername_rsid", mode: 'rellink', overwrite: true, enabled: params.dev
    publishDir "${params.outdir}/intermediates/liftover_branch_markername_rsid/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev

    input:
    tuple val(datasetID), path(rsidprep), val(snpExists)

    output:
    tuple val(datasetID), path("gb_unique_rows_2"), val(snpExists), emit: ch_liftover_3333
    tuple val(datasetID), path("removed_duplicated_rows_2"), emit: ch_removed_rows_before_liftover_ix_rsids
    path("beforeLiftoverFiltering_executionorder_2"), emit: intermediate

    script:
    out1="gb_unique_rows_2"
    out2="removed_duplicated_rows_2"
    out3="beforeLiftoverFiltering_executionorder_2"
    beforeLiftoverFilter=params.beforeLiftoverFilter

    """
    remove_duplicated_rsid_before_liftmap.sh $rsidprep $snpExists $beforeLiftoverFilter $out1 $out2 $out3

    """
}

process maplift_dbsnp_GRCh38_rsid {
   publishDir "${params.outdir}/intermediates/liftover_branch_markername_rsid", mode: 'rellink', overwrite: true, enabled: params.dev
   publishDir "${params.outdir}/intermediates/liftover_branch_markername_rsid/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev

   input:
   tuple val(datasetID), path(fsorted), val(snpExists)

   output:
   tuple val(datasetID), path("maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38"), emit: ch_liftover_rsid
   tuple val(datasetID), path("maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover_ix"), emit: ch_not_matching_during_liftover_rsid

   script:
   dbsnp_RSID_38=file(params.dbsnp_RSID_38)
   """

   if [ "${snpExists}" == "true" ]
   then
     #in gb_lifted_and_mapped_to_GRCh38, the order will be
     #GRCh38, GRCh37, rowIndex, RSID, REF, ALT
     #chr:pos | inx | rsid | a1 | a2 | chr:pos2 (if available)
     LC_ALL=C join -1 1 -2 1 ${fsorted} ${dbsnp_RSID_38} | awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$1,\$4,\$5}'  > maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38

     # Lines not possible to map
     LC_ALL=C join -v 1 -1 1 -2 3 ${fsorted} maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38 > maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover
     awk -vOFS="\t" '{print \$2,"not_matching_during_liftover"}' maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover > maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover_ix
   else
     #make empty file (has no header)
     touch maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38
     touch maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover_ix
   fi


   # Process before and after stats
   rowsBefore="\$(wc -l ${fsorted} | awk '{print \$1-1}')"
   rowsAfter="\$(wc -l maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38 | awk '{print \$1}')"
   echo -e "\$rowsBefore\t\$rowsAfter\tLiftover to GRCh38 and simultaneously map to dbsnp" > desc_liftover_to_GRCh38_and_map_to_dbsnp_BA

   """
} 


// LIFTOVER BRANCH 2 - chrpos mapping
process is_chrpos_different_from_snp_and_assign_dID2 {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(sfile), val(chrposExists), val(snpExists), val(pointsToDifferentCols)

    output:
    tuple val(datasetID), env(dID2), path("is_chrpos_different_from_snp_and_assign_dID2__prep_chrpos"), val(snpExists)

    script:
    """
    dID2="liftover_branch_chrpos"

    if [ "${chrposExists}" == "true" ] && [ "${pointsToDifferentCols}" == "true" ]
    then
      cp ${sfile} is_chrpos_different_from_snp_and_assign_dID2__prep_chrpos
    else
      head -n1 ${sfile} > is_chrpos_different_from_snp_and_assign_dID2__prep_chrpos
    fi

    """
}


//reformat_X_Y_XY_and_MT_and_remove_noninterpretables
process reformat_chromosome_information {
  publishDir "${params.outdir}/intermediates/reformat_chromosome_information/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev

  input:
  tuple val(datasetID), val(dID2), path(sfile), val(chrposexist)

  output:
  tuple val(datasetID), val(dID2), path("gb_ready_to_join_to_detect_build_sorted"), emit: ch_chromosome_fixed
  tuple val(datasetID), env(rowsAfter), emit: ch_rowsAfter_number_of_lines
  path('new_chr_sex_format*'), emit: intermediate

  script:
  def metadata = params.sess.get_metadata(datasetID)
  ch_regexp_lexicon=file(params.ch_regexp_lexicon)
  """

  if [ "${dID2}" == "liftover_branch_markername_chrpos" ];then
    map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "chr" "Markername" > adhoc_func
    map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "bp" "Markername" > adhoc_func1
  elif [ "${dID2}" == "liftover_branch_chrpos" ];then
    map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "chr" "${metadata.col_CHR ?: "missing"}" > adhoc_func
    map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "bp" "${metadata.col_POS ?: "missing"}" > adhoc_func1
  else
    echo 2>1 "neither Markername nor Chromosome position information used"
    exit 1;
  fi

  colCHR="\$(cat adhoc_func)"
  cat $sfile | sstools-utils ad-hoc-do -k "0|\${colCHR}" -n"0,CHR" > new_chr_sex_format0
  reformat_chromosome_information.sh new_chr_sex_format0 "CHR" prep_sfile_forced_sex_chromosome_format

  colPOS="\$(cat adhoc_func1)"
  cat ${sfile} | sstools-utils ad-hoc-do -k "0|\${colPOS}" -n"0,BP" > prep_sfile_selected_pos_prep

  #combine and sort
  LC_ALL=C join --header -1 1 -2 1 prep_sfile_forced_sex_chromosome_format prep_sfile_selected_pos_prep > gb_extract_and_format_chr_and_pos_to_detect_build
  awk -vOFS="\t" '{print \$2":"\$3,\$1}' gb_extract_and_format_chr_and_pos_to_detect_build > gb_ready_to_join_to_detect_build
  LC_ALL=C sort -k1,1 gb_ready_to_join_to_detect_build > gb_ready_to_join_to_detect_build_sorted

  # Process before and after stats (the -1 is to remove the header count)
  rowsBefore="\$(wc -l $sfile | awk '{print \$1-1}')"
  rowsAfter="\$(wc -l gb_ready_to_join_to_detect_build_sorted | awk '{print \$1-1}')"
  echo -e "\$rowsBefore\t\$rowsAfter\tforced sex chromosomes and mitochondria chr annotation to the numbers 23-26" > desc_sex_chrom_formatting_BA.txt

  #if [ "$dID2" == "liftover_branch_markername_chrpos" ];then
  #  echo "dID2 $dID2"
  #  echo "chrposexist $chrposexist"
  #  head $sfile
  #  exit 1
  #fi

  """
}

process detect_genome_build {

    publishDir "${params.outdir}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(dID2), val(sfile_chrpos)
    each build

    output:
    tuple val(datasetID), val(dID2), path("detect_genome_build__*.res"), emit: ch_genome_build_stats
    //file("gb_*")

    script:
    def metadata = params.sess.get_metadata(datasetID)
    ch_dbsnp_35_38=file(params.dbsnp_35_38)
    ch_dbsnp_36_38=file(params.dbsnp_36_38)
    ch_dbsnp_37_38=file(params.dbsnp_37_38)
    ch_dbsnp_38=file(params.dbsnp_38)
    """
    #check number of rows in file
    nrrows="\$(wc -l ${sfile_chrpos})"
    #if only header row, then do nothing
    if [ "\${nrrows}" == "1" ]
    then
      #I here choose to set number of mapped to 0, as nothing has been mapped.
      echo -e "0\t${build}" > ${datasetID}.${build}.res
    else
      format_chrpos_for_dbsnp.sh ${build} ${sfile_chrpos} ${ch_dbsnp_35_38} ${ch_dbsnp_36_38} ${ch_dbsnp_37_38} ${ch_dbsnp_38} > ${build}.map
      sort -u -k1,1 ${build}.map | wc -l | awk -vOFS="\t" -vbuild=${build} '{print \$1,build}' > detect_genome_build__${build}.res
    fi

    """
}

process decide_genome_build {
    publishDir "${params.outdir}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(dID2), path(ujoins)
    //tuple datasetID, dID2, file(ujoins) from ch_genome_build_stats_grouped

    output:
    tuple val(datasetID), val(dID2), env(GRChmax), emit: ch_known_genome_build
    //tuple datasetID, dID2, env(GRChmax) into ch_known_genome_build
    tuple val(datasetID), val(dID2), path("decide_genome_build__stats"), emit: ch_stats_genome_build_chrpos
    //tuple datasetID, dID2, file("decide_genome_build__stats") into ch_stats_genome_build_chrpos
    tuple val(datasetID), val(dID2), path("decide_genome_build__GRChOther"), env(GRChmaxVal), emit: ch_build_stats_for_failsafe
    //tuple datasetID, dID2, file("decide_genome_build__GRChOther"), env(GRChmaxVal) into ch_build_stats_for_failsafe
    path("decide_genome_build__GRChmax"), emit: intermediate

    script:
    """
    for gbuild in ${ujoins}
    do
        cat \$gbuild >> decide_genome_build__stats
    done
    GRChmax="\$(cat decide_genome_build__stats | sort -nr -k1,1 | head -n1 | awk '{print \$2}')"
    GRChmaxVal="\$(cat decide_genome_build__stats | sort -nr -k1,1 | head -n1 | awk '{print \$1}')"

    cat decide_genome_build__stats | sort -nr -k1,1 | tail -n+2 > decide_genome_build__GRChOther
    echo \${GRChmax} > decide_genome_build__GRChmax

    """
}


process build_warning {

  publishDir "${params.outdir}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(tot), val(dID2), path(buildstat), val(grmax)
    //tuple val(datasetID), val(tot), val(dID2), path(buildstat), val(grmax) from ch_failsafe

    output:
    tuple val(datasetID), path("warningsFile"), emit: ch_warning_liftover

    script:
    """
    #make empty warningsfile
    touch warningsFile

    #if tot is not 0
    if [ "${tot}" == "0" ]; then
      :
    else
      #check if anything should be added to the warningsfile
      warnings_liftover_percentage.sh ${grmax} ${tot} ${buildstat} ${dID2} >> warningsFile
    fi
    """
}


process rm_dup_chrpos_before_maplift {

    publishDir "${params.outdir}/intermediates/${dID2}/debugging", mode: 'rellink', overwrite: true, enabled: params.dev
    publishDir "${params.outdir}/intermediates/${dID2}/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev

    input:
    tuple val(datasetID), val(dID2), val(gbmax), path(chrposprep)

    output:
    tuple val(datasetID), val(dID2), path("gb_unique_rows_2"), val(gbmax), emit: ch_liftover_333
    tuple val(datasetID), path("removed_duplicated_rows_2"), emit: ch_removed_rows_before_liftover_ix_chrpos
    path("beforeLiftoverFiltering_executionorder_2"), emit: intermediate
    path("*"), emit: intermediate2

    script:
    out1="gb_unique_rows_2"
    out2="removed_duplicated_rows_2"
    out3="beforeLiftoverFiltering_executionorder_2"
    beforeLiftoverFilter=params.beforeLiftoverFilter
    """
    rm_dup_chrpos_before_maplift.sh $chrposprep $beforeLiftoverFilter $out1 $out2 $out3
    """
}

process maplift_dbsnp_GRCh38_chrpos {

  publishDir "${params.outdir}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev
  publishDir "${params.outdir}/intermediates/${dID2}/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev

  input:
  tuple val(datasetID), val(dID2), val(gbmax), path(fsorted)
  //tuple val(datasetID), val(dID2), path(fsorted), val(gbmax) 
  //tuple datasetID, dID2, mfile, fsorted, gbmax from ch_liftover_333

  output:
  tuple val(datasetID), val(dID2), path("maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38"), emit: ch_liftover_44
  //tuple datasetID, dID2, mfile, file("maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38") into ch_liftover_44
  //tuple datasetID, file("desc_liftover_to_GRCh38_and_map_to_dbsnp_BA") into ch_desc_liftover_to_GRCh38_and_map_to_dbsnp_BA_chrpos
  tuple val(datasetID), path("maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover_ix"), emit: ch_not_matching_during_liftover_chrpos
  //tuple datasetID, file("maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover_ix") into ch_not_matching_during_liftover_chrpos
  path("maplift_dbsnp_GRCh38_chrpos__lifted_middle_step*")

  script:
  ch_dbsnp_35_38=file(params.dbsnp_35_38)
  ch_dbsnp_36_38=file(params.dbsnp_36_38)
  ch_dbsnp_37_38=file(params.dbsnp_37_38)
  ch_dbsnp_38=file(params.dbsnp_38)
  """

  #check number of rows in file
  nrrows="\$(wc -l ${fsorted})"
  #if only header row, then do nothing
  if [ "\${nrrows}" == "1" ]
  then
    #I here choose to set number of mapped to 0, as nothing has been mapped. This file does not have a header.
    touch maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38

    #nothing should be in here
    touch maplift_dbsnp_GRCh38_chrpos__lifted_middle_step

    #as the this subset of the data is empty, we have to make this file empty as well
    # even though it would have been more logical to fill it with all lines from the original sfile
    touch maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover
    touch maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover_ix
  else

    #in gb_lifted_and_mapped_to_GRCh37_and_GRCh38, the order will be
    #GRCh38, GRCh37, rowIndex, RSID, REF, ALT
    #chr:pos | inx | rsid | a1 | a2 | chr:pos2 (if available)
    if [ "${gbmax}" == "GRCh38" ] ; then
      LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
      awk -vFS="[[:space:]]" -vOFS="\t" '{print \$1,\$2,\$3,\$4,\$5}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
    elif [ "${gbmax}" == "GRCh37" ] ; then
      LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_37_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
      awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$4,\$5,\$6}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
    elif [ "${gbmax}" == "GRCh36" ] ; then
      LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_36_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
      awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$4,\$5,\$6}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
    elif [ "${gbmax}" == "GRCh35" ] ; then
      LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_35_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
      awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$4,\$5,\$6}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
    else
      echo "${gbmax} is none of the available builds 35, 36, 37 or 38"
    fi


    # Lines not possible to map
    LC_ALL=C join -v 1 -1 1 -2 1 ${fsorted} maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover
    awk -vOFS="\t" '{print \$2,"not_matching_during_liftover"}' maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover > maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover_ix

  fi

  #process before and after stats
  rowsBefore="\$(wc -l ${fsorted} | awk '{print \$1-1}')"
  rowsAfter="\$(wc -l maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38 | awk '{print \$1}')"
  echo -e "\$rowsBefore\t\$rowsAfter\tLiftover to GRCh38 and simultaneously map to dbsnp" > desc_liftover_to_GRCh38_and_map_to_dbsnp_BA
  """
}



process select_chrpos_or_snpchrpos {
  publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

  input:
  tuple val(datasetID), val(dID2), path("liftedGRCh38"), val(dID2SNP), path("liftedGRCh38SNP"), path(liftedGRCh38RSID), path(beforeLiftover)

  output:
  tuple val(datasetID), path("select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted"), emit: ch_liftover_final
  tuple val(datasetID), path("select_chrpos_or_snpchrpos__beforeAndAfterFile"), emit: ch_desc_combined_set_after_liftover
  tuple val(datasetID), path("select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set_ix"), emit: ch_removed_not_possible_to_lift_over_for_combined_set_ix
 // file("liftedGRCh38_sorted")
 // file("rsid_to_add")
 // file("snpchrpos_unique")
 // file("snpchrpos_to_add")
 // file("tmp_test")

  script:
  """
  LC_ALL=C sort -k1,1 ${beforeLiftover} > beforeLiftover_sorted
  #any row inx from rsid or snpchrpos not in chrpos
  LC_ALL=C sort -k2,2 "liftedGRCh38" > liftedGRCh38_sorted
  LC_ALL=C sort -k2,2 ${liftedGRCh38RSID} > liftedGRCh38RSID_sorted
  LC_ALL=C sort -k2,2 "liftedGRCh38SNP" > liftedGRCh38SNP_sorted
  LC_ALL=C join -t "\$(printf '\t')" -v 1 -1 2 -2 2 -o 1.1 1.2 1.3 1.4 1.5 liftedGRCh38RSID_sorted liftedGRCh38_sorted > rsid_to_add
  LC_ALL=C join -t "\$(printf '\t')" -v 1 -1 2 -2 2 -o 1.1 1.2 1.3 1.4 1.5 liftedGRCh38SNP_sorted liftedGRCh38_sorted > snpchrpos_unique
  LC_ALL=C join -t "\$(printf '\t')" -v 1 -1 2 -2 2 -o 1.1 1.2 1.3 1.4 1.5 snpchrpos_unique rsid_to_add > snpchrpos_to_add

  #if so, then add it to the output
  cat liftedGRCh38_sorted rsid_to_add snpchrpos_to_add > combined_set_from_the_three_liftover_branches
  LC_ALL=C sort -k2,2 combined_set_from_the_three_liftover_branches > select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted

  # Lines not possible to map for the combined set
  LC_ALL=C join -v 1 -1 1 -2 2 beforeLiftover_sorted select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted > select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set
  awk -vOFS="\t" '{print \$1,"not_available_for_any_of_the_three_liftover_branches"}' select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set > select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set_ix

  #process before and after stats
  rowsBefore="\$(wc -l ${beforeLiftover} | awk '{print \$1-1}')"
  rowsAfter="\$(wc -l select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted | awk '{print \$1}')"
  echo -e "\$rowsBefore\t\$rowsAfter\tAfter creating the combined set from the three liftover paths" > select_chrpos_or_snpchrpos__beforeAndAfterFile

  """
}


// Causes more harm than good now when multi-allelics are allowed
//process rm_dup_chrpos_allele_rows {
//
//    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
//    publishDir "${params.outdir}/intermediates/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev
//
//    input:
//    tuple val(datasetID), path(liftedandmapped)
//
//    output:
//    tuple val(datasetID), path("rm_dup_chrpos_allele_rows__gb_unique_rows_sorted"), emit: ch_liftover_4
//    tuple val(datasetID), path("rm_dup_chrpos_allele_rows__desc_removed_duplicated_rows"), emit: ch_desc_removed_duplicates_after_liftover
//    tuple val(datasetID), path("rm_dup_chrpos_allele_rows__removed_duplicated_rows"), emit: ch_removed_duplicates_after_liftover_ix
//
//    script:
//    afterLiftoverFilter=params.afterLiftoverFilter
//    """
//    filter_after_liftover.sh $liftedandmapped "${afterLiftoverFilter} " "rm_dup_chrpos_allele_rows__"
//
//    """
//}


process reformat_sumstat {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(liftedandmapped)
    //tuple val(datasetID), path(liftedandmapped) from ch_liftover_4

    output:
    tuple val(datasetID), val("GRCh38"), path("reformat_sumstat__gb_lifted_GRCh38"), emit: ch_mapped_GRCh38
    //tuple val(datasetID), val("GRCh38"), path("reformat_sumstat__gb_lifted_GRCh38") into ch_mapped_GRCh38
    tuple val(datasetID), path("reformat_sumstat__desc_keep_a_GRCh38_reference_BA.txt"), emit: ch_desc_keep_a_GRCh38_reference_BA
    //tuple val(datasetID), path("reformat_sumstat__desc_keep_a_GRCh38_reference_BA.txt") into ch_desc_keep_a_GRCh38_reference_BA

    script:
    """
    #prepare GRCh38 for downstream analysis
    awk -vFS="[[:space:]]" -vOFS="\t" '{print \$2,\$1,\$3,\$4,\$5}' $liftedandmapped > reformat_sumstat__gb_lifted_GRCh38

    #process before and after stats
    rowsBefore="\$(wc -l $liftedandmapped | awk '{print \$1}')"
    rowsAfter="\$(wc -l reformat_sumstat__gb_lifted_GRCh38 | awk '{print \$1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tSplit off a version of GRCh38 as coordinate reference" > reformat_sumstat__desc_keep_a_GRCh38_reference_BA.txt
    """
}



process split_multiallelics_resort_rowindex {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(build), path(liftgrs)
    //tuple datasetID, build, mfile, liftgrs from ch_mapped_GRCh38

    output:
    tuple val(datasetID), val(build), path("split_multiallelics_resort_rowindex__gb_multialleles_splittorows"), emit: ch_allele_correction
    //tuple val(datasetID), val(build), path("split_multiallelics_resort_rowindex__gb_multialleles_splittorows") into ch_allele_correction
    tuple val(datasetID), path("split_multiallelics_resort_rowindex__desc_split_multi_allelics_and_sort_on_rowindex_BA.txt"), emit: ch_desc_split_multi_allelics_and_sort_on_rowindex_BA
    //tuple val(datasetID), path("split_multiallelics_resort_rowindex__desc_split_multi_allelics_and_sort_on_rowindex_BA.txt") into ch_desc_split_multi_allelics_and_sort_on_rowindex_BA
    //file("split_multiallelics_resort_rowindex__gb_splitted_multiallelics")

    script:
    """
    split_multiallelics_to_rows.sh $liftgrs > split_multiallelics_resort_rowindex__gb_splitted_multiallelics
    echo -e "0\tCHRPOS\tRSID\tA1\tA2" > split_multiallelics_resort_rowindex__gb_multialleles_splittorows
    LC_ALL=C sort -k1,1 split_multiallelics_resort_rowindex__gb_splitted_multiallelics >> split_multiallelics_resort_rowindex__gb_multialleles_splittorows

    #process before and after stats (rows is -1 because of header)
    rowsBefore="\$(wc -l $liftgrs | awk '{print \$1}')"
    rowsAfter="\$(wc -l split_multiallelics_resort_rowindex__gb_multialleles_splittorows | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tSplit multi-allelics to multiple rows and sort on original rowindex " > split_multiallelics_resort_rowindex__desc_split_multi_allelics_and_sort_on_rowindex_BA.txt

    """
}

process remove_chrpos_allele_duplicates {
    publishDir "${params.outdir}/intermediates/remove_chrpos_allele_duplicates", mode: 'rellink', overwrite: true, enabled: params.dev
    publishDir "${params.outdir}/intermediates/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_records.txt', enabled: params.dev

    input:
    tuple val(datasetID), val(build), path(sumstats_file)

    output:
    tuple val(datasetID), val(build), path("filtered_records.txt"), emit: filtered_records
    tuple val(datasetID), path("removed_records.txt"), emit: removed_records
    tuple val(datasetID), path("desc_removed_duplicates_BA.txt"), emit: desc_removed_duplicates_BA

    script:
    """
    # Remove duplicates and output filtered and removed records
    remove_chrpos_allele_duplicates.sh ${sumstats_file} filtered_records.txt removed_records_temp.txt

    # Format the removed records with proper exclusion reason
    awk -vOFS="\t" '{print \$1,"duplicated_chr_pos_a1_a2_after_mapping"}' removed_records_temp.txt > removed_records.txt

    # Generate before/after stats
    rowsBefore="\$(wc -l ${sumstats_file} | awk '{print \$1-1}')"
    rowsAfter="\$(wc -l filtered_records.txt | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tRemoved duplicate chr:pos entries" > desc_removed_duplicates_BA.txt
    """
}

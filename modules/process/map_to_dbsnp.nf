
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

process is_chrpos_different_from_snp_and_assign_dID2 {
    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(mfile), path(sfile), val(chrposExists), val(snpExists), val(pointsToDifferentCols)
    //tuple datasetID, mfile, sfile, chrposExists, snpExists, pointsToDifferentCols from ch_present_markers_2

    output:
    tuple val(datasetID), env(dID2), path(mfile), path("is_chrpos_different_from_snp_and_assign_dID2__prep_chrpos")
    //tuple datasetID, env(dID2), mfile, file("is_chrpos_different_from_snp_and_assign_dID2__prep_chrpos"), snpExists into ch_chrpos_init

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

//
//    // LIFTOVER BRANCH 1
//
process prepare_dbsnp_mapping_for_rsid {
    publishDir "${params.outdir}/${datasetID}/intermediates/prepare_dbsnp_mapping_for_rsid", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(mfile), path(sfile), val(chrposExists), val(snpExists), val(pointsToDifferentCols), val(colSNP)
    //tuple datasetID, mfile, sfile, chrposExists, snpExists, pointsToDifferentCols from ch_present_markers_1

    output:
    tuple val(datasetID), path(mfile), path("prepare_dbsnp_mapping_for_rsid__db_maplift"), val(snpExists), emit: ch_liftover_33
    //tuple datasetID, mfile, file("prepare_dbsnp_mapping_for_rsid__db_maplift"), snpExists into ch_liftover_33
    tuple val(datasetID), env(dID2), path(mfile), path("prepare_dbsnp_mapping_for_rsid__gb_lift2"), val(snpExists), emit: ch_liftover_snpchrpos
    //tuple datasetID, env(dID2), mfile, file("prepare_dbsnp_mapping_for_rsid__gb_lift2"), snpExists into ch_liftover_snpchrpos
    //tuple datasetID, file("desc_prepare_format_for_dbsnp_mapping_BA.txt") into ch_desc_prep_for_dbsnp_mapping_BA_chrpos_rsid
    //tuple datasetID, file("desc_sex_chrom_formatting_BA.txt") into ch_desc_sex_chrom_formatting_BA_1

    script:
    """
    dID2="liftover_branch_markername_chrpos"
    colSNP="${metadata.col_SNP ?: "missing"}"
    prepare_dbsnp_mapping_for_rsid.sh ${sfile} ${snpExists} prepare_dbsnp_mapping_for_rsid__db_maplift prepare_dbsnp_mapping_for_rsid__gb_lift2 \${colSNP}

    # Process before and after stats
    rowsBefore="\$(wc -l ${sfile} | awk '{print \$1-1}')"
    rowsAfter="\$(wc -l prepare_dbsnp_mapping_for_rsid__db_maplift | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tPrepare file for mapping to dbsnp by sorting the mapping index" > desc_prepare_format_for_dbsnp_mapping_BA.txt
    """
}
//
//    process remove_duplicated_rsid_before_liftmap {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates/liftover_branch_markername_rsid", mode: 'rellink', overwrite: true, enabled: params.dev
//        publishDir "${params.outdir}/${datasetID}/intermediates/liftover_branch_markername_rsid/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev
//
//        input:
//        tuple datasetID, mfile, rsidprep, snpExists from ch_liftover_33
//
//        output:
//        tuple datasetID, mfile, file("gb_unique_rows_2"), snpExists into ch_liftover_3333
//        //tuple datasetID, file("desc_removed_duplicated_rows_2") into ch_removed_rows_before_liftover_rsids
//        tuple datasetID, file("removed_duplicated_rows_2") into ch_removed_rows_before_liftover_ix_rsids
//        file("beforeLiftoverFiltering_executionorder_2")
//
//        script:
//        out1="gb_unique_rows_2"
//        out2="removed_duplicated_rows_2"
//        out3="beforeLiftoverFiltering_executionorder_2"
//        """
//        remove_duplicated_rsid_before_liftmap.sh $rsidprep $snpExists $beforeLiftoverFilter $out1 $out2 $out3
//
//        """
//    }
//
//    process maplift_dbsnp_GRCh38_rsid {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates/liftover_branch_markername_rsid", mode: 'rellink', overwrite: true, enabled: params.dev
//        publishDir "${params.outdir}/${datasetID}/intermediates/liftover_branch_markername_rsid/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev
//
//        input:
//        tuple datasetID, mfile, fsorted, snpExists from ch_liftover_3333
//
//        output:
//        tuple datasetID, mfile, file("maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38") into ch_liftover_rsid
//        //tuple datasetID, file("desc_liftover_to_GRCh38_and_map_to_dbsnp_BA") into ch_desc_liftover_to_GRCh38_and_map_to_dbsnp_BA_rsid
//        //tuple datasetID, file("${datasetID}.stats") into ch_stats_genome_build_rsid
//        tuple datasetID, file("maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover_ix") into ch_not_matching_during_liftover_rsid
//
//        script:
//        """
//
//        if [ "${snpExists}" == "true" ]
//        then
//          #in gb_lifted_and_mapped_to_GRCh38, the order will be
//          #GRCh38, GRCh37, rowIndex, RSID, REF, ALT
//          #chr:pos | inx | rsid | a1 | a2 | chr:pos2 (if available)
//          LC_ALL=C join -1 1 -2 1 ${fsorted} ${ch_dbsnp_RSID_38} | awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$1,\$4,\$5}'  > maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38
//
//          # Lines not possible to map
//          LC_ALL=C join -v 1 -1 1 -2 3 ${fsorted} maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38 > maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover
//          awk -vOFS="\t" '{print \$2,"not_matching_during_liftover"}' maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover > maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover_ix
//        else
//          #make empty file (has no header)
//          touch maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38
//          touch maplift_dbsnp_GRCh38_rsid__removed_not_matching_during_liftover_ix
//        fi
//
//
//        # Process before and after stats
//        rowsBefore="\$(wc -l ${fsorted} | awk '{print \$1-1}')"
//        rowsAfter="\$(wc -l maplift_dbsnp_GRCh38_rsid__gb_lifted_and_mapped_to_GRCh38 | awk '{print \$1}')"
//        echo -e "\$rowsBefore\t\$rowsAfter\tLiftover to GRCh38 and simultaneously map to dbsnp" > desc_liftover_to_GRCh38_and_map_to_dbsnp_BA
//
//        """
//    }
//
//
//    // LIFTOVER BRANCH 2 - chrpos mapping
//
//    //mix the snpchrpos (from markername column) with chrpos (from own columns)
//    ch_chrpos_init
//      .mix(ch_liftover_snpchrpos)
//      .set{ ch_liftover_snpchrpos_chrpos_mixed }
//
//      ch_liftover_snpchrpos_chrpos_mixed.into{ch_liftover_snpchrpos_chrpos_mixed1;ch_liftover_snpchrpos_chrpos_mixed2}
//    // ch_liftover_snpchrpos_chrpos_mixed2.view()
//
//    //reformat_X_Y_XY_and_MT_and_remove_noninterpretables
//    process reformat_chromosome_information {
//      publishDir "${params.outdir}/${datasetID}/intermediates/reformat_chromosome_information/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev
//
//      input:
//      tuple datasetID, dID2, mfile, sfile, chrposexist from ch_liftover_snpchrpos_chrpos_mixed1
//
//      output:
//      tuple datasetID, dID2, mfile, file("gb_ready_to_join_to_detect_build_sorted") into ch_chromosome_fixed
//      //tuple datasetID, file("desc_sex_chrom_formatting_BA.txt") into ch_desc_sex_chrom_formatting_BA_2
//      tuple datasetID, env(rowsAfter) into ch_rowsAfter_number_of_lines
//      file('new_chr_sex_format*')
//
//      script:
//      def metadata = session.get_metadata(datasetID)
//      """
//
//      if [ "${dID2}" == "liftover_branch_markername_chrpos" ];then
//        map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "chr" "Markername" > adhoc_func
//      elif [ "${dID2}" == "liftover_branch_chrpos" ];then
//        map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "chr" "${metadata.col_CHR ?: "missing"}" > adhoc_func
//      else
//        echo 2>1 "neither Markername nor Chromosome position information used"
//        exit 1;
//      fi
//
//      colCHR="\$(cat adhoc_func)"
//      cat $sfile | sstools-utils ad-hoc-do -k "0|\${colCHR}" -n"0,CHR" > new_chr_sex_format0
//      reformat_chromosome_information.sh new_chr_sex_format0 "CHR" prep_sfile_forced_sex_chromosome_format
//
//      colPOS="${metadata.col_POS ?: "missing"}"
//      map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "bp" "\${colPOS}" > adhoc_func1
//      colPOS="\$(cat adhoc_func1)"
//      cat ${sfile} | sstools-utils ad-hoc-do -k "0|\${colPOS}" -n"0,BP" > prep_sfile_selected_pos_prep
//
//      #combine and sort
//      LC_ALL=C join --header -1 1 -2 1 prep_sfile_forced_sex_chromosome_format prep_sfile_selected_pos_prep > gb_extract_and_format_chr_and_pos_to_detect_build
//      awk -vOFS="\t" '{print \$2":"\$3,\$1}' gb_extract_and_format_chr_and_pos_to_detect_build > gb_ready_to_join_to_detect_build
//      LC_ALL=C sort -k1,1 gb_ready_to_join_to_detect_build > gb_ready_to_join_to_detect_build_sorted
//
//      # Process before and after stats (the -1 is to remove the header count)
//      rowsBefore="\$(wc -l $sfile | awk '{print \$1-1}')"
//      rowsAfter="\$(wc -l gb_ready_to_join_to_detect_build_sorted | awk '{print \$1-1}')"
//      echo -e "\$rowsBefore\t\$rowsAfter\tforced sex chromosomes and mitochondria chr annotation to the numbers 23-26" > desc_sex_chrom_formatting_BA.txt
//
//      """
//    }
//
//    ch_chromosome_fixed.into {ch_chromosome_fixed1; ch_chromosome_fixed2}
//
//    whichbuild = ['GRCh35', 'GRCh36', 'GRCh37', 'GRCh38']
//
//    process detect_genome_build {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev
//
//        input:
//        tuple datasetID, dID2, mfile, sfile_chrpos from ch_chromosome_fixed1
//        each build from whichbuild
//
//        output:
//        tuple datasetID, dID2, file("detect_genome_build__*.res") into ch_genome_build_stats
//        //file("gb_*")
//
//        script:
//        def metadata = session.get_metadata(datasetID)
//        """
//
//        #check number of rows in file
//        nrrows="\$(wc -l ${sfile_chrpos})"
//        #if only header row, then do nothing
//        if [ "\${nrrows}" == "1" ]
//        then
//          #I here choose to set number of mapped to 0, as nothing has been mapped.
//          echo -e "0\t${build}" > ${datasetID}.${build}.res
//        else
//          format_chrpos_for_dbsnp.sh ${build} ${sfile_chrpos} ${ch_dbsnp_35_38} ${ch_dbsnp_36_38} ${ch_dbsnp_37_38} ${ch_dbsnp_38} > ${build}.map
//          sort -u -k1,1 ${build}.map | wc -l | awk -vOFS="\t" -vbuild=${build} '{print \$1,build}' > detect_genome_build__${build}.res
//        fi
//
//        """
//    }
//
//
//    ch_genome_build_stats_grouped = ch_genome_build_stats.groupTuple(by:[0,1],size:4)
//
//    process decide_genome_build {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev
//
//        input:
//        tuple datasetID, dID2, file(ujoins) from ch_genome_build_stats_grouped
//
//
//        output:
//        tuple datasetID, dID2, env(GRChmax) into ch_known_genome_build
//        tuple datasetID, dID2, file("decide_genome_build__stats") into ch_stats_genome_build_chrpos
//        tuple datasetID, dID2, file("decide_genome_build__GRChOther"), env(GRChmaxVal) into ch_build_stats_for_failsafe
//        path("decide_genome_build__GRChmax")
//
//        script:
//        """
//        for gbuild in ${ujoins}
//        do
//            cat \$gbuild >> decide_genome_build__stats
//        done
//        GRChmax="\$(cat decide_genome_build__stats | sort -nr -k1,1 | head -n1 | awk '{print \$2}')"
//        GRChmaxVal="\$(cat decide_genome_build__stats | sort -nr -k1,1 | head -n1 | awk '{print \$1}')"
//
//        cat decide_genome_build__stats | sort -nr -k1,1 | tail -n+2 > decide_genome_build__GRChOther
//        echo \${GRChmax} > decide_genome_build__GRChmax
//
//        """
//    }
//
//
//    ch_rowsAfter_number_of_lines
//      .join(ch_build_stats_for_failsafe, by: 0)
//      .set{ ch_failsafe }
//
//    process build_warning {
//
//      publishDir "${params.outdir}/${datasetID}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev
//
//        input:
//        tuple datasetID, tot, dID2, buildstat, grmax from ch_failsafe
//
//        output:
//        tuple datasetID, file("warningsFile") into ch_warning_liftover
//
//        script:
//        """
//        #make empty warningsfile
//        touch warningsFile
//
//        #if tot is not 0
//        if [ "${tot}" == "0" ]; then
//          :
//        else
//          #check if anything should be added to the warningsfile
//          warnings_liftover_percentage.sh ${grmax} ${tot} ${buildstat} ${dID2} >> warningsFile
//        fi
//        """
//    }
//
//    // Add respective sumstat file from the parallell paths
//    ch_liftover_3=ch_known_genome_build.join(ch_chromosome_fixed2, by: [0,1])
//
//    process rm_dup_chrpos_before_maplift {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev
//        publishDir "${params.outdir}/${datasetID}/intermediates/${dID2}/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev
//
//        input:
//   //     tuple datasetID, dID2, mfile, chrposprep, gbmax from ch_liftover_3
//        tuple datasetID, dID2, gbmax, mfile, chrposprep from ch_liftover_3
//
//        output:
//        tuple datasetID, dID2, mfile, file("gb_unique_rows_2"), gbmax into ch_liftover_333
//        //tuple datasetID, file("desc_removed_duplicated_rows") into ch_removed_rows_before_liftover_chrpos
//        tuple datasetID, file("removed_duplicated_rows_2") into ch_removed_rows_before_liftover_ix_chrpos
//        file("beforeLiftoverFiltering_executionorder_2")
//
//        script:
//        out1="gb_unique_rows_2"
//        out2="removed_duplicated_rows_2"
//        out3="beforeLiftoverFiltering_executionorder_2"
//        """
//        rm_dup_chrpos_before_maplift.sh $chrposprep $beforeLiftoverFilter $out1 $out2 $out3
//
//        """
//    }
//
//
//  process maplift_dbsnp_GRCh38_chrpos {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates/${dID2}", mode: 'rellink', overwrite: true, enabled: params.dev
//        publishDir "${params.outdir}/${datasetID}/intermediates/${dID2}/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev
//
//        input:
//        tuple datasetID, dID2, mfile, fsorted, gbmax from ch_liftover_333
//
//        output:
//        tuple datasetID, dID2, mfile, file("maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38") into ch_liftover_44
//        //tuple datasetID, file("desc_liftover_to_GRCh38_and_map_to_dbsnp_BA") into ch_desc_liftover_to_GRCh38_and_map_to_dbsnp_BA_chrpos
//        tuple datasetID, file("maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover_ix") into ch_not_matching_during_liftover_chrpos
//        //file("removed_*")
//        file("maplift_dbsnp_GRCh38_chrpos__lifted_middle_step*")
//
//        script:
//        """
//
//        #check number of rows in file
//        nrrows="\$(wc -l ${fsorted})"
//        #if only header row, then do nothing
//        if [ "\${nrrows}" == "1" ]
//        then
//          #I here choose to set number of mapped to 0, as nothing has been mapped. This file does not have a header.
//          touch maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
//
//          #nothing should be in here
//          touch maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
//
//          #as the this subset of the data is empty, we have to make this file empty as well
//          # even though it would have been more logical to fill it with all lines from the original sfile
//          touch maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover
//          touch maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover_ix
//        else
//
//          #in gb_lifted_and_mapped_to_GRCh37_and_GRCh38, the order will be
//          #GRCh38, GRCh37, rowIndex, RSID, REF, ALT
//          #chr:pos | inx | rsid | a1 | a2 | chr:pos2 (if available)
//          if [ "${gbmax}" == "GRCh38" ] ; then
//            LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
//            awk -vFS="[[:space:]]" -vOFS="\t" '{print \$1,\$2,\$3,\$4,\$5}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
//          elif [ "${gbmax}" == "GRCh37" ] ; then
//            LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_37_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
//            awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$4,\$5,\$6}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
//          elif [ "${gbmax}" == "GRCh36" ] ; then
//            LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_36_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
//            awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$4,\$5,\$6}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
//          elif [ "${gbmax}" == "GRCh35" ] ; then
//            LC_ALL=C join -1 1 -2 1 $fsorted ${ch_dbsnp_35_38} > maplift_dbsnp_GRCh38_chrpos__lifted_middle_step
//            awk -vFS="[[:space:]]" -vOFS="\t" '{print \$3,\$2,\$4,\$5,\$6}' maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38
//          else
//            echo "${gbmax} is none of the available builds 35, 36, 37 or 38"
//          fi
//
//
//          # Lines not possible to map
//          LC_ALL=C join -v 1 -1 1 -2 1 ${fsorted} maplift_dbsnp_GRCh38_chrpos__lifted_middle_step > maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover
//          awk -vOFS="\t" '{print \$2,"not_matching_during_liftover"}' maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover > maplift_dbsnp_GRCh38_chrpos__removed_not_matching_during_liftover_ix
//
//        fi
//
//        #process before and after stats
//        rowsBefore="\$(wc -l ${fsorted} | awk '{print \$1-1}')"
//        rowsAfter="\$(wc -l maplift_dbsnp_GRCh38_chrpos__gb_lifted_and_mapped_to_GRCh38 | awk '{print \$1}')"
//        echo -e "\$rowsBefore\t\$rowsAfter\tLiftover to GRCh38 and simultaneously map to dbsnp" > desc_liftover_to_GRCh38_and_map_to_dbsnp_BA
//        """
//    }
//
//    //branch the chrpos and snpchrpos channels
//    ch_chrpos_snp_filter=ch_liftover_44.branch { key, value, mfile, liftedGRCh38 ->
//                    liftover_branch_markername_chrpos: value == "liftover_branch_markername_chrpos"
//                    liftover_branch_chrpos: value == "liftover_branch_chrpos"
//                    }
//    ch_chrpos=ch_chrpos_snp_filter.liftover_branch_chrpos
//    ch_snpchrpos=ch_chrpos_snp_filter.liftover_branch_markername_chrpos
//
//    //join the chrpos and snpchrpos channels
//    ch_chrpos
//      .join(ch_snpchrpos, by: 0)
//      .join(ch_liftover_rsid, by: 0)
//      .join(ch_before_liftover, by: 0)
//      .set{ ch_combined_chrpos_snpchrpos_rsid }
//
//process select_chrpos_or_snpchrpos {
//
//      publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
//
//      input:
//      tuple datasetID, dID2, mfile, liftedGRCh38, dID2SNP, mfileSNP, liftedGRCh38SNP, mfileRSID, liftedGRCh38RSID, beforeLiftover from ch_combined_chrpos_snpchrpos_rsid
//
//      output:
//      tuple datasetID, mfile, file("select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted") into ch_liftover_final
//      tuple datasetID, file("select_chrpos_or_snpchrpos__beforeAndAfterFile") into ch_desc_combined_set_after_liftover
//      tuple datasetID, file("select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set_ix") into ch_removed_not_possible_to_lift_over_for_combined_set_ix
//      file("liftedGRCh38_sorted")
//      file("rsid_to_add")
//      file("snpchrpos_unique")
//      file("snpchrpos_to_add")
//      file("tmp_test")
//
//      script:
//      """
//      cp ${beforeLiftover} tmp_test
//      #any row inx from rsid or snpchrpos not in chrpos
//      LC_ALL=C sort -k2,2 ${liftedGRCh38} > liftedGRCh38_sorted
//      LC_ALL=C sort -k2,2 ${liftedGRCh38RSID} > liftedGRCh38RSID_sorted
//      LC_ALL=C sort -k2,2 ${liftedGRCh38SNP} > liftedGRCh38SNP_sorted
//      LC_ALL=C join -t "\$(printf '\t')" -v 1 -1 2 -2 2 -o 1.1 1.2 1.3 1.4 1.5 liftedGRCh38RSID_sorted liftedGRCh38_sorted > rsid_to_add
//      LC_ALL=C join -t "\$(printf '\t')" -v 1 -1 2 -2 2 -o 1.1 1.2 1.3 1.4 1.5 liftedGRCh38SNP_sorted liftedGRCh38_sorted > snpchrpos_unique
//      LC_ALL=C join -t "\$(printf '\t')" -v 1 -1 2 -2 2 -o 1.1 1.2 1.3 1.4 1.5 snpchrpos_unique rsid_to_add > snpchrpos_to_add
//
//      #if so, then add it to the output
//      cat liftedGRCh38_sorted rsid_to_add snpchrpos_to_add > combined_set_from_the_three_liftover_branches
//      LC_ALL=C sort -k2,2 combined_set_from_the_three_liftover_branches > select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted
//
//      # Lines not possible to map for the combined set
//      LC_ALL=C join -t "\$(printf '\t')" -v 1 -1 2 -2 1 -o 2.1 select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted ${beforeLiftover} > select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set
//      awk -vOFS="\t" '{print \$1,"not_available_for_any_of_the_three_liftover_branches"}' select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set > select_chrpos_or_snpchrpos__removed_not_possible_to_lift_over_for_combined_set_ix
//
//      #process before and after stats
//      rowsBefore="\$(wc -l ${beforeLiftover} | awk '{print \$1-1}')"
//      rowsAfter="\$(wc -l select_chrpos_or_snpchrpos__combined_set_from_the_three_liftover_branches_sorted | awk '{print \$1}')"
//      echo -e "\$rowsBefore\t\$rowsAfter\tAfter creating the combined set from the three liftover paths" > select_chrpos_or_snpchrpos__beforeAndAfterFile
//      """
//}
//
//    //branch the stats_genome_build
//    ch_stats_genome_build_filter=ch_stats_genome_build_chrpos.branch { key, value, file ->
//                    liftover_branch_markername_chrpos: value == "liftover_branch_markername_chrpos"
//                    liftover_branch_chrpos: value == "liftover_branch_chrpos"
//                    }
//    ch_stats_chrpos_gb=ch_stats_genome_build_filter.liftover_branch_chrpos
//    ch_stats_snpchrpos_gb=ch_stats_genome_build_filter.liftover_branch_markername_chrpos
//
//    //combine the chrpos and snpchrpos channels for genome build
//    ch_stats_chrpos_gb
//      .join(ch_stats_snpchrpos_gb, by: 0)
//      .map { key, val, file, val2, file2 -> tuple(key, file, file2) }
//      .set{ ch_gb_stats_combined }
//
//
//    process rm_dup_chrpos_allele_rows {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
//        publishDir "${params.outdir}/${datasetID}/intermediates/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev
//
//        input:
//        tuple datasetID, mfile, liftedandmapped from ch_liftover_final
//
//        output:
//        tuple datasetID, mfile, file("rm_dup_chrpos_allele_rows__gb_unique_rows_sorted") into ch_liftover_4
//        tuple datasetID, file("rm_dup_chrpos_allele_rows__desc_removed_duplicated_rows") into ch_desc_removed_duplicates_after_liftover
//        tuple datasetID, file("rm_dup_chrpos_allele_rows__removed_duplicated_rows") into ch_removed_duplicates_after_liftover_ix
//        //file("removed_*")
//        //file("afterLiftoverFiltering_executionorder")
//
//        script:
//        """
//        filter_after_liftover.sh $liftedandmapped "${afterLiftoverFilter} " "rm_dup_chrpos_allele_rows__"
//
//        """
//    }
//
//
//    process reformat_sumstat {
//        publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
//
//        input:
//        tuple datasetID, mfile, liftedandmapped from ch_liftover_4
//
//        output:
//        tuple datasetID, val("GRCh38"), mfile, file("reformat_sumstat__gb_lifted_GRCh38") into ch_mapped_GRCh38
//        tuple datasetID, file("reformat_sumstat__desc_keep_a_GRCh38_reference_BA.txt") into ch_desc_keep_a_GRCh38_reference_BA
//
//        script:
//        """
//        #prepare GRCh38 for downstream analysis
//        awk -vFS="[[:space:]]" -vOFS="\t" '{print \$2,\$1,\$3,\$4,\$5}' $liftedandmapped > reformat_sumstat__gb_lifted_GRCh38
//
//        #process before and after stats
//        rowsBefore="\$(wc -l $liftedandmapped | awk '{print \$1}')"
//        rowsAfter="\$(wc -l reformat_sumstat__gb_lifted_GRCh38 | awk '{print \$1}')"
//        echo -e "\$rowsBefore\t\$rowsAfter\tSplit off a version of GRCh38 as coordinate reference" > reformat_sumstat__desc_keep_a_GRCh38_reference_BA.txt
//        """
//    }
//
//
//    process split_multiallelics_resort_rowindex {
//
//        publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
//
//        input:
//        tuple datasetID, build, mfile, liftgrs from ch_mapped_GRCh38
//
//        output:
//        tuple datasetID, build, mfile, file("split_multiallelics_resort_rowindex__gb_multialleles_splittorows") into ch_allele_correction
//        tuple datasetID, file("split_multiallelics_resort_rowindex__desc_split_multi_allelics_and_sort_on_rowindex_BA.txt") into ch_desc_split_multi_allelics_and_sort_on_rowindex_BA
//        file("split_multiallelics_resort_rowindex__gb_splitted_multiallelics")
//
//        script:
//        """
//        split_multiallelics_to_rows.sh $liftgrs > split_multiallelics_resort_rowindex__gb_splitted_multiallelics
//        echo -e "0\tCHRPOS\tRSID\tA1\tA2" > split_multiallelics_resort_rowindex__gb_multialleles_splittorows
//        LC_ALL=C sort -k1,1 split_multiallelics_resort_rowindex__gb_splitted_multiallelics >> split_multiallelics_resort_rowindex__gb_multialleles_splittorows
//
//        #process before and after stats (rows is -1 because of header)
//        rowsBefore="\$(wc -l $liftgrs | awk '{print \$1}')"
//        rowsAfter="\$(wc -l split_multiallelics_resort_rowindex__gb_multialleles_splittorows | awk '{print \$1-1}')"
//        echo -e "\$rowsBefore\t\$rowsAfter\tSplit multi-allelics to multiple rows and sort on original rowindex " > split_multiallelics_resort_rowindex__desc_split_multi_allelics_and_sort_on_rowindex_BA.txt
//
//        """
//    }

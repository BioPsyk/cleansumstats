process final_assembly {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(build), path(acorrected), path(stats)
    //from ch_allele_corrected_and_outstats

    output:
    tuple val(datasetID), path("final_assembly__cleaned2"), path("final_assembly__header"), emit: cleaned_file
    tuple val(datasetID), path("final_assembly__desc_final_merge_BA.txt"), emit: ch_desc_final_merge_BA
    //path("final_assembly__cleaned")

    script:
    """
    apply_modifier_on_stats.sh $acorrected $stats > final_assembly__cleaned

    #sort on chrpos (which will make header not on top, so lift that out, and prepare order for next process)
    head -n1 final_assembly__cleaned | awk -vFS="\t" -vOFS="\t" '{printf "%s%s%s%s%s%s", \$2, OFS, \$3, OFS, \$1, OFS; for(i=4; i<=NF-1; i++){printf "%s%s", \$i, OFS}; print \$NF}' > final_assembly__header
    awk -vFS="\t" -vOFS="\t" 'NR>1{printf "%s%s%s%s", \$2":"\$3, OFS, \$1, OFS; for(i=4; i<=NF-1; i++){printf "%s%s", \$i, OFS}; print \$NF}' final_assembly__cleaned | LC_ALL=C sort -k1,1 > final_assembly__cleaned2

    # process before and after stats
    rowsBefore="\$(wc -l $acorrected | awk '{print \$1}')"
    rowsAfter="\$(wc -l final_assembly__cleaned2 | awk '{print \$1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFrom dbsnp mapped to merged selection of stats, final step" > final_assembly__desc_final_merge_BA.txt
    """
}


process prep_GRCh37_coord {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(cleaned_chrpos_sorted), path(header)
    //tuple val(datasetID), path(cleaned_chrpos_sorted), path(header) from ch_cleaned_file_1

    output:
    tuple val(datasetID), path("prep_GRCh37_coord__cleaned_chrpos_sorted_header"), path("prep_GRCh37_coord__cleaned_GRCh37"), emit: ch_cleaned_file
    //file("cleaned_chrpos_sorted")
    //file("inx_chrpos_GRCh37")

    script:
    ch_dbsnp_38_37=file(params.dbsnp_38_37)
    """
    echo -e "CHR\tPOS\tRSID" > prep_GRCh37_coord__cleaned_GRCh37
    LC_ALL=C join -e "NA" -a1 -1 1 -2 1 -o 2.1 2.2 2.3 ${cleaned_chrpos_sorted} ${ch_dbsnp_38_37} | awk -vOFS="\t" '{split(\$2,out,":"); print out[1], out[2],\$3 }' >> prep_GRCh37_coord__cleaned_GRCh37
    cat $header > prep_GRCh37_coord__cleaned_chrpos_sorted_header
    awk -vFS="\t" -vOFS="\t" '{split(\$1,out,":");printf "%s%s%s%s", out[1], OFS, out[2], OFS; for(i=2; i<=NF-1; i++){printf "%s%s", \$i, OFS}; print \$NF}' $cleaned_chrpos_sorted >> prep_GRCh37_coord__cleaned_chrpos_sorted_header
    """

}


process collect_rmd_lines {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(step1), path(step2), path(step3)
    //from ch_collected_removed_lines
    output:
    tuple val(datasetID), path("collect_rmd_lines__removed_lines_collected.txt"), emit: ch_collected_removed_lines2
    //tuple datasetID, file("collect_rmd_lines__removed_lines_collected.txt") into ch_collected_removed_lines2

    script:
    """
    echo -e "RowIndex\tExclusionReason" > collect_rmd_lines__removed_lines_collected.txt
    cat ${step1} ${step2} ${step3} >> collect_rmd_lines__removed_lines_collected.txt
    """
}

process desc_rmd_lines_as_table {

  publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(filtered_stats_removed)
    //tuple val(datasetID), path(filtered_stats_removed) from ch_collected_removed_lines3

    output:
    tuple val(datasetID), path("desc_rmd_lines_as_table__desc_removed_lines_table.txt"), emit: ch_removed_lines_table

    script:
    """
    # prepare process specific descriptive statistics
    echo -e "NrExcludedRows\tExclusionReason" > desc_rmd_lines_as_table__desc_removed_lines_table.txt
    cat $filtered_stats_removed | tail -n+2 | awk -vOFS="\t" '{ seen[\$2] += 1 } END { for (i in seen) print seen[i],i }' >> desc_rmd_lines_as_table__desc_removed_lines_table.txt

    """
}


process gzip_outfiles {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(sclean), path(scleanGRCh37), path(inputsfile), path(inputformatted), path(removedlines)
    //from ch_to_write_to_filelibrary2

    output:
    tuple val(datasetID), path("gzip_outfiles__sclean.gz"), path("gzip_outfiles__scleanGRCh37.gz"), emit: gz_to_write
    tuple val(datasetID), path("gzip_outfiles__removed_lines.gz"), emit: gz_rm_lines_to_write
    tuple val(datasetID), path("gzip_outfiles__cleanedheader"), emit: ch_cleaned_header
    tuple val(datasetID), path(inputsfile), emit: ch_to_write_to_raw_library
    val(datasetID), emit: ch_check_avail

    script:
    """
    # Make a header file to use when deciding on what cols are present for the new meta file
    head -n1 ${sclean} > gzip_outfiles__cleanedheader

    # Store data in library
    gzip -c ${sclean} > gzip_outfiles__sclean.gz
    gzip -c ${scleanGRCh37} > gzip_outfiles__scleanGRCh37.gz
    gzip -c ${removedlines} > gzip_outfiles__removed_lines.gz
    """
}
  
//    ch_to_write_to_filelibrary3.into { ch_to_write_to_filelibrary3a; ch_to_write_to_filelibrary3b }
  
process calculate_checksum_on_sumstat_cleaned {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(sclean), path(scleanGRCh37), path(removedlines)
    //from ch_to_write_to_filelibrary3a

    output:
    tuple val(datasetID), env(scleanchecksum), env(scleanGRCh37checksum), env(removedlineschecksum), emit: ch_cleaned_sumstat_checksums

    script:
    """
    scleanchecksum="\$(b3sum ${sclean} | awk '{print \$1}')"
    scleanGRCh37checksum="\$(b3sum ${scleanGRCh37} | awk '{print \$1}')"
    removedlineschecksum="\$(b3sum ${removedlines} | awk '{print \$1}')"
    """
}

process collect_and_prep_stepwise_readme {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), 
    path(step1),
    path(step2), 
    path(step3), 
    path(step4), 
    path(step5), 
    path(step6), 
    path(step7), 
    path(step8), 
    path(step9), 
    path(step10), 
    path(step11), 
    path(step12), 
    path(step13) 
    //from ch_collected_workflow_stepwise_stats

    output:
    tuple val(datasetID), path("collect_and_prep_stepwise_readme__desc_collected_workflow_stepwise_stats.txt"), emit: ch_overview_workflow_steps

    script:
    """
    cat $step1 $step2 $step3 $step4 $step5 $step6 $step7 $step8 $step9 $step10 $step11 $step12 $step13 > all_removed_steps

    echo -e "Steps\tBefore\tAfter\tDescription" > collect_and_prep_stepwise_readme__desc_collected_workflow_stepwise_stats.txt
    awk -vFS="\t" -vOFS="\t" '{print "Step"NR, \$1, \$2, \$3}' all_removed_steps >> collect_and_prep_stepwise_readme__desc_collected_workflow_stepwise_stats.txt

    """
}

process prepare_cleaned_metadata_file {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(usermetachecksum), val(rawsumstatchecksum), val(scleanchecksum), val(scleanGRCh37checksum), val(removedlineschecksum), val(cleanedheader)
    //from ch_mfile_cleaned_x

    output:
    tuple val(datasetID), path("prepare_cleaned_metadata_file__prepared_cleaned_metafile"), emit: ch_mfile_cleaned_1

    script:
    def metadata = params.sess.get_metadata(datasetID)
    stats_TraitType="${metadata.stats_TraitType ?: "missing"}"
    stats_TotalN="${metadata.stats_TotalN ?: "missing"}"
    stats_CaseN="${metadata.stats_CaseN ?: "missing"}"
    stats_ControlN="${metadata.stats_ControlN ?: "missing"}"
    """

    #Add cleaned output lines
    dateOfCreation="\$(date +%F-%H%M)"
    echo "cleansumstats_date: \${dateOfCreation}" > mfile_additions
    echo "cleansumstats_user: \$(id -u -n)" >> mfile_additions
    echo "cleansumstats_cleaned_GRCh38: sumstat_cleaned_GRCh38.gz" >> mfile_additions
    echo "cleansumstats_cleaned_GRCh38_checksum: ${scleanchecksum}" >> mfile_additions
    echo "cleansumstats_cleaned_GRCh37_coordinates: sumstat_cleaned_GRCh37.gz" >> mfile_additions
    echo "cleansumstats_cleaned_GRCh37_coordinates_checksum: ${scleanGRCh37checksum}" >> mfile_additions
    echo "cleansumstats_removed_lines: sumstat_removed_lines.gz" >> mfile_additions
    echo "cleansumstats_removed_lines_checksum: ${removedlineschecksum}" >> mfile_additions
    echo "cleansumstats_metafile_user_checksum: ${usermetachecksum}" >> mfile_additions
    echo "cleansumstats_sumstat_raw_checksum: ${rawsumstatchecksum}" >> mfile_additions

    #Calcualate effective N using meta data info
    try_infere_Neffective.sh \
    ${stats_TraitType} \
    ${stats_TotalN} \
    ${stats_CaseN} \
    ${stats_ControlN} \
    >> mfile_additions

    # Apply additions to make the cleaned meta file ready
    create_output_meta_data_file_cleaned.sh mfile_additions ${cleanedheader} > prepare_cleaned_metadata_file__prepared_cleaned_metafile
      """
}

process add_cleaned_to_output {

    publishDir "${params.outdir}", mode: 'copy', overwrite: true

    input:
    tuple val(datasetID), 
    path(sclean), 
    path(scleanGRCh37),
    path(cleanmfile)

    output:
    path("*")

    script:
    """
    # Store data in library by copying (move is faster, but debug gets slower as input disappears)
    cp ${sclean} cleaned_GRCh38.gz
    cp ${scleanGRCh37} cleaned_GRCh37.gz
    cp ${cleanmfile} cleaned_metadata.yaml

    """
}

process add_details_to_output {

    publishDir "${params.details}", mode: 'copy', overwrite: true

    input:
    tuple val(datasetID), 
    path("gbdetectCHRPOS"),
    path("gbdetectSNPCHRPOS"),
    path(selected_source),
    path(removedlines), 
    path(overviewworkflow),
    path(removedlinestable)

    output:
    path("*")

    script:
    """
    # Make a folder with detailed data of the cleaning
    cp $overviewworkflow stepwise_overview.txt
    cp ${removedlinestable} removed_lines_per_type_table.txt
    cp "gbdetectCHRPOS" genome_build_map_count_table_chrpos.txt
    cp "gbdetectSNPCHRPOS" genome_build_map_count_table_markername.txt
    cp ${removedlines} removed_lines.gz
    cp ${selected_source} selected_source_stats.txt

    """
}

process add_raw_to_output {

    //Because of name clashes and missing files, publishDir is not feasible
    //publishDir "${params.rawoutput}", mode: 'copy', overwrite: true

    input:
    tuple val(datasetID), 
    path(usermfile),
    val(readme),
    val(pmid),
    val(pdfpath), 
    val(pdfsuppdir), 
    path(rawfile)

    when:
    params.rawoutput != false

    script:
    """
    # make dir if not existing
    mkdir -p ${params.rawoutput}

    # copy all raw stuff into rawinput
    cp ${rawfile} ${params.rawoutput}/.
    cp ${usermfile} ${params.rawoutput}/.

    if [ "${readme}" != "missing" ]
    then
      cp ${pdfpath} ${params.rawoutput}/.
    fi

    if [ "${pdfpath}" != "missing" ]
    then
      cp ${pdfpath} ${params.rawoutput}/.
    fi

    for supp in ${pdfsuppdir};do
       if [ "\${supp}" != "missing" ]
       then
         cp \$supp ${params.rawoutput}/.
       else
         :
       fi
    done
    """
}


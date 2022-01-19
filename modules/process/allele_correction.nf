//    ch_allele_correction_combine.into{ ch_allele_correction_combine1; ch_allele_correction_combine2 }
//
//process does_exist_A2 {
//
//    input:
//    tuple datasetID, mfile from ch_mfile_ok2
//
//    output:
//    tuple datasetID, A2exists into ch_present_A2
//
//    script:
//    """
//    echo ${A2exists} > A2exists
//    """
process allele_correction_A1_A2 {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
    publishDir "${params.outdir}/intermediates/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev

    input:
    tuple val(datasetID),val(build), path(mapped), path(sfile), val(A2exists)
    //tuple val(datasetID),val(build), path(mapped), path(sfile), val(A2exists) from ch_A2_exists

    output:
    tuple val(datasetID), val(build), path("allele_correction_A1_A2__acorrected"), emit: ch_A2_exists2
    //tuple datasetID, build, mfile, file("allele_correction_A1_A2__acorrected") into ch_A2_exists2
    tuple val(datasetID), path("allele_correction_A1_A2__removed_allele_filter_ix"), emit: ch_removed_by_allele_filter_ix1
    //tuple datasetID, file("allele_correction_A1_A2__removed_allele_filter_ix") into ch_removed_by_allele_filter_ix1
    tuple val(datasetID), path("allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference"), emit: ch_desc_filtered_allele_pairs_with_dbsnp_as_reference_A1A2_BA
    //tuple datasetID, file("allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference") into ch_desc_filtered_allele_pairs_with_dbsnp_as_reference_A1A2_BA

    script:
    def metadata = params.sess.get_metadata(datasetID)
    ch_regexp_lexicon=params.ch_regexp_lexicon
    """

    colEff="${metadata.col_EffectAllele ?: "missing"}"
    colAlt="${metadata.col_OtherAllele ?: "missing"}"
    map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "effallele" "\${colEff}" > adhoc_func1
    map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "altallele" "\${colAlt}" > adhoc_func2
    colA1="\$(cat adhoc_func1)"
    colA2="\$(cat adhoc_func2)"

    allele_correction.sh ${sfile} ${mapped} "\${colA1}" "\${colA2}" allele_correction_A1_A2__acorrected allele_correction_A1_A2__removed_allele_filter_ix

    #process before and after stats (create one for each discarded filter, the original before after concept where all output files are directly tested is a bit violated here as we have to count down from input file)
    rowsBefore="\$(wc -l ${mapped} | awk '{print \$1-1}')"
    rowsAfter="\$(wc -l removed_notGCTA | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on nonGTAC characters" >> allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_indel | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on indels. All indels in the dbsnp reference are already filtered out" >> allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_hom | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on homozygotes. Should be rare." >> allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_palin | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on palindromes. Usually a substantial amount." >> allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_notPossPair | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on not possible pair combinations comparing with reference db. Many multi-allelic sites are filtered out here" >> allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_notExpA2 | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on not expected otherAllele in reference db" >> allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l allele_correction_A1_A2__acorrected | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tAllele corretion sanity check that final filtered file before and after file have same row count" >> allele_correction_A1_A2__desc_filtered_allele-pairs_with_dbsnp_as_reference
    """
}

process allele_correction_A1 {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
    publishDir "${params.outdir}/intermediates/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev

    input:
    tuple val(datasetID), val(build), path(mapped), path(sfile), val(A2missing)
    //tuple val(datasetID), val(build), path(mapped), path(sfile), val(A2missing) from ch_A2_missing

    output:
    tuple val(datasetID), val(build), path("allele_correction_A1__acorrected"), emit: ch_A2_missing2
    //tuple datasetID, build, mfile, file("allele_correction_A1__acorrected") into ch_A2_missing2
    tuple val(datasetID), path("allele_correction_A1__removed_allele_filter_ix"), emit: ch_removed_by_allele_filter_ix2
    //tuple datasetID, file("allele_correction_A1__removed_allele_filter_ix") into ch_removed_by_allele_filter_ix2
    tuple val(datasetID), path("allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference"), emit: ch_desc_filtered_allele_pairs_with_dbsnp_as_reference_A1_BA
    //tuple datasetID, file("allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference") into ch_desc_filtered_allele_pairs_with_dbsnp_as_reference_A1_BA
    script:
    def metadata = params.sess.get_metadata(datasetID)
    ch_regexp_lexicon=params.ch_regexp_lexicon
    """
    colEff="${metadata.col_EffectAllele ?: "missing"}"
    map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "effallele" "\${colEff}" > adhoc_func1
    colA1="\$(cat adhoc_func1)"

    #NOTE to use A1 allele only complicates the filtering on possible pairs etc, so we always need a multiallelic filter in how the filter works right now.
    # This is something we should try to accomodate to, so that it is not required.
    multiallelic_filter.sh $mapped > allele_correction_A1__multifiltered

    allele_correction_onlyA1.sh ${sfile} allele_correction_A1__multifiltered "\${colA1}" allele_correction_A1__acorrected allele_correction_A1__removed_allele_filter_ix
    #process before and after stats (create one for each discarded filter, the original before after concept where all output files are directly tested is a bit violated here as we have to count down from input file)
    rowsBefore="\$(wc -l ${mapped} | awk '{print \$1-1}')"
    rowsAfter="\$(wc -l removed_notGCTA | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on nonGTAC characters" >> allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_indel | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on indels. All indels in the dbsnp reference are already filtered out" >> allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_hom | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on homozygotes. Should be rare." >> allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_palin | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on palindromes" >> allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_notPossPair | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on not possible pair combinations comparing with reference db. Many multi-allelic sites are filtered out here" >> allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l removed_notExpA2 | awk -vrb=\${rowsBefore} '{ra=rb-\$1; print ra}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFiltered rows on not expected otherAllele in reference db" >> allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference

    rowsBefore="\${rowsAfter}"
    rowsAfter="\$(wc -l allele_correction_A1__acorrected | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tsanity sanity check that final filtered file before and after file have same row count" >> allele_correction_A1__desc_filtered_allele-pairs_with_dbsnp_as_reference


    """
}

process rm_dup_chrpos_rows_after_acor {
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(build), path(acorrected)
    //tuple datasetID, build, mfile, acorrected from ch_allele_corrected_mix_X

    output:
    tuple val(datasetID), val(build), path("rm_dup_chrpos_rows_after_acor__ac_unique_rows_sorted"), emit: ch_allele_corrected_mix_Y
    //tuple val(datasetID), val(build), path("rm_dup_chrpos_rows_after_acor__ac_unique_rows_sorted") into ch_allele_corrected_mix_Y
    tuple val(datasetID), path("rm_dup_chrpos_rows_after_acor__desc_removed_duplicated_rows"), emit: ch_desc_removed_duplicated_chr_pos_rows_BA
    //tuple val(datasetID), path("rm_dup_chrpos_rows_after_acor__desc_removed_duplicated_rows") into ch_desc_removed_duplicated_chr_pos_rows_BA
    //file("ac_*")
    //file("afterAlleleCorrection_executionorder")
    //file("removed_*")

    script:
    afterAlleleCorrectionFilter=params.afterAlleleCorrectionFilter
    """

    #Can be used as a sanitycheck-filter to discover potential misbehaviour
    # Added white space after "afterAlleleCorrectionFilter" as if it is empty, then the third argument will go one step forward
    filter_after_allele_correction.sh ${acorrected} "${afterAlleleCorrectionFilter} " "rm_dup_chrpos_rows_after_acor__"

    """
}

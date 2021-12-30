
process calculate_checksum_on_metafile_input {
    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(mfile)
    //from ch_mfile_user_3


    output:
    tuple val(datasetID), env(usermetachecksum), emit: main
    //into ch_usermeta_checksum
    path("calculate_checksum_on_metafile_input__input_meta_checksum.txt"), emit: intermediate

    script:
    """
    b3sum ${mfile} | awk '{print \$1}' > calculate_checksum_on_metafile_input__input_meta_checksum.txt
    usermetachecksum="\$(cat calculate_checksum_on_metafile_input__input_meta_checksum.txt)"
    """
}


process make_metafile_unix_friendly {
    publishDir "${params.outdir}/${datasetID}/intermediates/make_metafile_unix_friendly", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path("input_mfile_raw")
    //tuple val(datasetID), path("input_mfile_raw") from ch_mfile_user_1

    output:
    tuple val(datasetID), path("input_mfile_raw"), path("output__mfile_unix_safe")
    //tuple val(datasetID), path("input_mfile_raw"), path("output__mfile_unix_safe") into ch_mfile_unix_safe

    script:
    """
    make_metafile_unix_friendly.sh input_mfile_raw output__mfile_unix_safe
    """
}

//ch_input_sfile.into { ch_input_sfile1; ch_input_sfile2 }

process calculate_checksum_on_sumstat_input {
    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(sfile)
    //tuple datasetID, sfile from ch_input_sfile1

    output:
    tuple val(datasetID), env(rawsumstatchecksum), emit: main
    //tuple datasetID, env(rawsumstatchecksum) into ch_rawsumstat_checksum
    path("calculate_checksum_on_sumstat_input__input_sumstat_checksum"), emit: intermediate

    script:
    """
    b3sum ${sfile} | awk '{print \$1}' > calculate_checksum_on_sumstat_input__input_sumstat_checksum
    rawsumstatchecksum="\$(cat 'calculate_checksum_on_sumstat_input__input_sumstat_checksum')"
    """
}
  
// Force into the right format if possible
process check_sumstat_format {

    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(mfile), path(sfilePath)
    //tuple datasetID, mfile, sfilePath from ch_mfile_check_format

    output:
    tuple val(datasetID), path(mfile), emit: mfile
    //tuple datasetID, mfile into ch_mfile_ok
    tuple val(datasetID), path("check_sumstat_format__sumstat_file"), emit: sfile
    //tuple datasetID, file("check_sumstat_format__sumstat_file") into ch_sfile_ok
    tuple val(datasetID), path("check_sumstat_format__desc_force_tab_sep_BA.txt"), emit: desc
    //tuple datasetID, file("check_sumstat_format__desc_force_tab_sep_BA.txt") into ch_desc_prep_force_tab_sep_BA
    tuple path("check_sumstat_format__sumstat_1000_rows"), path("check_sumstat_format__sumstat_1000_rows_formatted"), path("*.log"), emit: intermediate
    
    script:
    """
    # Sumstat file check on first 1000 lines
    echo "\$(head -n 1000 < <(zcat ${sfilePath}))" | gzip -c > check_sumstat_format__sumstat_1000_rows
    check_and_format_sfile.sh check_sumstat_format__sumstat_1000_rows check_sumstat_format__sumstat_1000_rows_formatted check_sumstat_format__sumstat_1000_rows_formatted.log

    # Make second sumstat file check on all lines
    check_and_format_sfile.sh ${sfilePath} check_sumstat_format__sumstat_file check_sumstat_format__sumstat_file.log

    # Process before and after stats (the -1 is to remove the header count)
    rowsBefore="\$(zcat ${sfilePath} | wc -l | awk '{print \$1-1}')"
    rowsAfter="\$(wc -l check_sumstat_format__sumstat_file | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tForce tab separation" > check_sumstat_format__desc_force_tab_sep_BA.txt
    """
}

process add_sorted_rowindex_to_sumstat {
    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(sfile)
    //tuple val(datasetID), path(sfile) from ch_sfile_ok

    output:
    tuple val(datasetID), path("add_index_sumstat__added_rowindex_sumstat_file"), emit: main
    //tuple datasetID, file("add_index_sumstat__added_rowindex_sumstat_file") into ch_sfile_on_stream
    tuple val(datasetID), path("add_index_sumstat__desc_before_after"), emit: desc
    //tuple datasetID, file("add_index_sumstat__desc_before_after") into ch_desc_prep_add_sorted_rowindex_BA

    script:
    """
    add_sorted_rowindex_to_sumstat.sh $sfile > add_index_sumstat__added_rowindex_sumstat_file

    #process before and after stats (the -1 is to remove the header count)
    rowsBefore="\$(wc -l $sfile | awk '{print \$1-1}')"
    rowsAfter="\$(wc -l add_index_sumstat__added_rowindex_sumstat_file | awk '{print \$1-1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tAdd rowindex, which maps back to the unfiltered file" > add_index_sumstat__desc_before_after
    """
}


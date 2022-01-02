process final_assembly {
    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

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

    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

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


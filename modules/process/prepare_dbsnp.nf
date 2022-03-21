process dbsnp_reference_convert_and_split {
  
  publishDir "${params.outdir}/intermediates/dbsnp_reference_convert_and_split", mode: 'rellink', overwrite: true, enabled: params.dev
  cpus 3
  
  input:
  tuple val(basefilename), path(dbsnpvcf)
  val(dbsnpsplits)
  
  output:
  path("chunk_*"), emit: dbsnp_split
  path("dbsnp_GRCh38"), emit: dbsnp_GRCh38
  
  script:
  """
  #reformat (pigz can't use parallel processes when decompressing)
  pigz --decompress --stdout --processes 2 ${dbsnpvcf} | grep -v "#" > dbsnp_GRCh38
  #split into dbsnpsplit number of unix split files
  split -d -n l/${dbsnpsplits} dbsnp_GRCh38 chunk_
  """
}

process dbsnp_reference_reformat {

  publishDir "${params.outdir}/intermediates/dbsnp_reference_reformat", mode: 'rellink', overwrite: true, enabled: params.dev
  cpus 1
  
  input:
  tuple val(cid), path(dbsnp_chunk)
  
  output:
  tuple val(cid), path("GRCh38.bed_${cid}")
  
  script:
  """
  awk '{print "chr"\$1, \$2, \$2,  \$1":"\$2, \$3, \$4, \$5}' ${dbsnp_chunk} > GRCh38.bed_${cid}
  """
}

process dbsnp_reference_rm_indels {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_rm_indels", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(cid), path(dbsnp_chunk)

    output:
    tuple val(cid), path("GRCh38.bed.noindel_${cid}")

    script:
    """
    # Remove all insertions or deletions
    # this will eliminate some rsids, both the ones with multiple rsids for the exact same snp, but also the ones with ref and alt switched.
    awk ' \$7 !~ /,/{if(length(\$6)!=1 || length(\$7)!=1 || \$6=="." || \$7=="."){print \$0 > "rm_indels"}else{print \$0}}; \$7 ~ /,/{if(\$7 ~ /\\w\\w/){print \$0 > "rm_indels2"}else{print \$0}} ' ${dbsnp_chunk} > GRCh38.bed.noindel_${cid}
    """
}

process dbsnp_reference_report_number_of_biallelic_multiallelics {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_report_number_of_biallelic_multiallelics", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(cid), path(dbsnp_chunk)

    output:
    tuple val(cid), path("*")

    script:
    """
    ## investigate the amount of single base multi allelics left (without filtering them out from the main workflow)
    awk ' \$7 ~ /,/{print \$0} ' ${dbsnp_chunk} > biallelic_multiallelics_${cid}
    """
}

process dbsnp_reference_merge_before_duplicate_filters_GRCh38 {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 4

    input:
    path(dbsnp_chunks)

    output:
    path("GRCh38_merge.bed")

    script:
    """
    # Concatenate
    for chunk in ${dbsnp_chunks}
    do
      cat \${chunk} >> "GRCh38_merge.bed"
    done

    """
}

process dbsnp_reference_rm_dup_positions_GRCh38 {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_rm_dup_positions_GRCh38", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 4

    input:
    path(GRCh38_all)

    output:
    path("GRCh38.bed.nodup"), emit: nodup
    path("GRCh38.bed.dup"), emit: dup

    script:
    """
    dbsnp_reference_duplicate_position_filter.sh ${GRCh38_all} GRCh38.bed.nodup GRCh38.bed.dup

    """
}

// again split before liftover
process dbsnp_split_before_2nd_liftover {

    publishDir "${params.outdir}/intermediates/dbsnp_split_before_2nd_liftover", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 3

    input:
    path("dbsnp_GRCh38")
    val(dbsnpsplits)

    output:
    path("chunk_*")
    script:
    """
    #split into dbsnpsplit number of unix split files
    split -d -n l/${dbsnpsplits} dbsnp_GRCh38 chunk_

    """
}

process dbsnp_reference_liftover_GRCh37 {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_liftover_GRCh37", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(cid), path(dbsnp_chunk)

    output:
    tuple val(cid), path("GRCh37_GRCh38_liftover_*")

    script:
    ch_hg38ToHg19chain=file(params.hg38ToHg19chain)
    """
    dbsnp_reference_liftover.sh ${dbsnp_chunk} ${ch_hg38ToHg19chain} ${cid} "${cid}_tmp2"
    awk '{tmp=\$1; sub(/[cC][hH][rR]/, "", tmp); print \$1, \$2, \$3, tmp":"\$2, \$4, \$5, \$6, \$7}' "${cid}_tmp2" > GRCh37_GRCh38_liftover_${cid}
    """
}

process dbsnp_reference_rm_liftover_remaining_ambigous_GRCh37 {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_rm_liftover_remaining_ambigous_GRCh37", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(cid), path(dbsnp_chunk)

    output:
    path("GRCh37_GRCh38.bed.chromclean_*"), emit: main
    path("GRCh37_GRCh38_all_chr_types_*"), emit: intermediate

    script:
    """
    #To get a list of all chromosomes types
    awk '{gsub(":.*","",\$1); print \$1}' ${dbsnp_chunk} | awk '{ seen[\$1] += 1 } END { for (i in seen) print seen[i],i }' > GRCh37_GRCh38_all_chr_types_${cid}

    #remove non standard chromosome names (seems like they include a "_" in the name)
    awk '{tmp=\$1; gsub(":.*","",\$1); if(\$1 !~ /_/ ){print tmp,\$2,\$3,\$4,\$5,\$6,\$7,\$8}}' ${dbsnp_chunk} > GRCh37_GRCh38.bed.chromclean_${cid}
    """
}

process dbsnp_reference_merge_before_duplicate_filters_GRCh37 {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 4

    input:
    path(dbsnp_chunks)

    output:
    path("GRCh37_GRCh38_merge.bed")

    script:
    """
    # Concatenate
    for chunk in ${dbsnp_chunks}
    do
      cat \${chunk} >> "GRCh37_GRCh38_merge.bed"
    done

    """
}

process dbsnp_reference_rm_dup_positions_GRCh37 {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_rm_dup_positions_GRCh37", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 4

    input:
    path("GRCh37_all")
    //from ch_merge_GRCh37

    output:
    path("GRCh37_GRCh38.bed.nodup"), emit: nodup
    path("GRCh37_GRCh38.bed.dup"), emit: dups

    script:
    """
    dbsnp_reference_duplicate_position_filter.sh GRCh37_all GRCh37_GRCh38.bed.nodup GRCh37_GRCh38.bed.dup
    """
}


// again split before liftover
process dbsnp_split_before_3rd_liftover {

    publishDir "${params.outdir}/intermediates/dbsnp_split_before_3rd_liftover", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 3

    input:
    path("dbsnp_GRCh37")
    val(dbsnpsplits)

    output:
    path("chunk_*")

    script:
    """
    #split into dbsnpsplit number of unix split files
    split -d -n l/${dbsnpsplits} dbsnp_GRCh37 chunk_

    """
}

process dbsnp_reference_liftover_GRCh36 {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_liftover_GRCh36", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(cid), path(dbsnp_chunk)
    //from ch_dbsnp_split6a

    output:
    tuple val("36"), val(cid), path("GRCh36_GRCh38.bed_*")
    //into ch_dbsnp_lifted_to_GRCh36

    script:
    ch_hg19ToHg18chain=file(params.hg19ToHg18chain)
    build = "36"
    """
    dbsnp_reference_liftover.sh ${dbsnp_chunk} ${ch_hg19ToHg18chain} ${cid} GRCh36_GRCh38.bed_${cid}
    """
}

process dbsnp_reference_liftover_GRCh35 {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_liftover_GRCh35", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(cid), path(dbsnp_chunk)
    //from ch_dbsnp_split6b
    output:
    tuple val("35"), val(cid), path("GRCh35_GRCh38.bed*")
    //into ch_dbsnp_lifted_to_GRCh35

    script:
    ch_hg19ToHg17chain=file(params.hg19ToHg17chain)
    build = "35"
    """
    dbsnp_reference_liftover.sh ${dbsnp_chunk} ${ch_hg19ToHg17chain} ${cid} GRCh35_GRCh38.bed_${cid}
    """
}

process dbsnp_reference_rm_liftover_remaining_ambigous_GRCh3x {

    publishDir "${params.outdir}/intermediates/dbsnp_reference_rm_liftover_remaining_ambigous_GRCh3x", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(build), val(cid), path(dbsnp_chunk)

    output:
    tuple val(build), path("GRCh${build}_GRCh38.bed.chromclean_${cid}"), emit: main
    path("GRCh${build}_GRCh38_all_chr_types_${cid}"), emit: intermeadiates

    script:
    """
    #To get a list of all chromosomes types
    awk '{gsub(":.*","",\$1); print \$1}' ${dbsnp_chunk} | awk '{ seen[\$1] += 1 } END { for (i in seen) print seen[i],i }' > GRCh${build}_GRCh38_all_chr_types_${cid}

    #remove non standard chromosome names (seems like they include a "_" in the name)
    awk '{tmp=\$1; gsub(":.*","",\$1); if(\$1 !~ /_/ ){print tmp,\$2,\$3,\$4,\$5,\$6,\$7,\$8}}' ${dbsnp_chunk} > GRCh${build}_GRCh38.bed.chromclean_${cid}
    """
}

process dbsnp_reference_merge_reference_library_GRCh3x_GRCh38 {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, pattern: '*.map', enabled: params.dev
    cpus 1

    input:
    tuple val(build), path(dbsnp_chunks)
    //from ch_dbsnp_lifted_to_GRCh3x_grouped)

    output:
    tuple val(build), path("${build}_GRCh38_merge.bed")
    //into ch_dbsnp_merged_GRCh3x

    script:
    // join all list elements by whitespace to be able to iterate using bash
    chunks_all=dbsnp_chunks.join(" ")
    """
    # Concatenate
    for chunk in ${chunks_all}
    do
      cat \${chunk} >> ${build}_GRCh38_merge.bed
    done
    """

}


process dbsnp_reference_rm_dup_positions_GRCh36_GRCh35 {


    publishDir "${params.outdir}/intermediates/dbsnp_reference_rm_dup_positions_GRCh36_GRCh35", mode: 'rellink', overwrite: true, enabled: params.dev
    cpus 1

    input:
    tuple val(build), path(dbsnp_merge)

    output:
    tuple val(build), path("${build}_GRCh38.bed.nodup"), emit: nodup
    //into ch_dbsnp_rmd_dup_positions_GRCh3x
    path("${build}_GRCh38.bed.dup"), emit: dups

    script:
    """
    # Remove all duplicated positions GRCh35 and GRCh36 (as some positions might have become duplicates after the liftover)
    dbsnp_reference_duplicate_position_filter.sh ${dbsnp_merge} ${build}_GRCh38.bed.nodup ${build}_GRCh38.bed.dup
    """
}

process dbsnp_reference_put_files_in_reference_library_RSID {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev, pattern: '*.map'
    publishDir "${params.libdirdbsnp}", mode: 'copy', overwrite: false, pattern: '*.bed'
    cpus 4

    input:
    path(GRCh38_all) 
    //from ch_dbsnp_rmd_dup_positions_GRCh38_2)

    output:
    path("${ch_dbsnp_RSID_38.baseName}.bed"), emit: main
    path("*.map"), emit: intermediates

    script:
    ch_dbsnp_RSID_38=file(params.dbsnp_RSID_38)
    """
    # Make version sorted on RSID to get correct coordinates
    awk '{print \$5, \$4, \$6, \$7}' ${GRCh38_all} > All_20180418_RSID_GRCh38.map

    # Sort
    mkdir -p tmp
    LC_ALL=C sort -k 1,1 \
    --parallel 4 \
    --temporary-directory=/cleansumstats/tmp \
    --buffer-size=20G \
    All_20180418_RSID_GRCh38.map \
    > "${ch_dbsnp_RSID_38.baseName}.bed"
    rm -r tmp

    """
}


process dbsnp_reference_put_files_in_reference_library_GRCh38 {

    publishDir "${params.libdirdbsnp}", mode: 'copy', overwrite: false, pattern: '*.bed'
    cpus 4

    input:
    path(dbsnp_final)
    //from ch_dbsnp_rmd_dup_positions_GRCh38_3

    output:
    path("${ch_dbsnp_38.baseName}.bed")

    script:
    ch_dbsnp_38=file(params.dbsnp_38)
    """
    awk '{print \$4, \$5, \$6, \$7}' ${dbsnp_final} > "${ch_dbsnp_38.baseName}.bed"
    """
}

process dbsnp_reference_put_files_in_reference_library_GRCh38_GRCh37 {

    publishDir "${params.libdirdbsnp}", mode: 'copy', overwrite: false, pattern: '*.bed'
    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, pattern: '*.map', enabled: params.dev
    cpus 4

    input:
    path("All_20180418_GRCh38_GRCh37_tmp.map")

    output:
    path("${ch_dbsnp_38_37.baseName}.bed")
    path("${ch_dbsnp_37_38.baseName}.bed")
    path("*map")

    script:
    ch_dbsnp_38_37=file(params.dbsnp_38_37)
    ch_dbsnp_37_38=file(params.dbsnp_37_38)
    """
    awk '{print \$4, \$5, \$6, \$7, \$8}' All_20180418_GRCh38_GRCh37_tmp.map > "${ch_dbsnp_37_38.baseName}.bed"
    awk '{print \$5, \$4, \$6, \$7, \$8}' All_20180418_GRCh38_GRCh37_tmp.map > All_20180418_GRCh38_GRCh37.map

    # Sort
    mkdir -p tmp
    LC_ALL=C sort -k 1,1 \
    --parallel 8 \
    --temporary-directory=tmp \
    --buffer-size=20G \
    All_20180418_GRCh38_GRCh37.map \
    > "${ch_dbsnp_38_37.baseName}.bed"
    rm -r tmp
    """
}

process dbsnp_reference_select_sort_and_put_files_in_reference_library_GRCh3x_GRCh38 {

    publishDir "${params.libdirdbsnp}", mode: 'copy', overwrite: false, pattern: '*.bed'
    cpus 4

    input:
    tuple val(build), path(dbsnp_chunks)
    //from ch_dbsnp_rmd_ambig_positions_GRCh3x_grouped

    output:
    path("*.bed")

    script:
    ch_dbsnp_36_38=file(params.dbsnp_36_38)
    ch_dbsnp_35_38=file(params.dbsnp_35_38)
    """
    # Select Cols and Sort on chr:pos
    if [ "${build}" == "36" ]; then
      awk '{tmp=\$1; sub(/[cC][hH][rR]/, "", tmp); print tmp":"\$2, \$5, \$6, \$7, \$8}' ${dbsnp_chunks} > file.tmp
      mkdir -p tmp
      LC_ALL=C sort -k 1,1 \
      --parallel 4 \
      --temporary-directory=tmp \
      --buffer-size=20G \
      file.tmp  > "${ch_dbsnp_36_38.baseName}.bed"
      rm -r tmp

    else
      awk '{tmp=\$1; sub(/[cC][hH][rR]/, "", tmp); print tmp":"\$2, \$5, \$6, \$7, \$8}' ${dbsnp_chunks} > file.tmp
      mkdir -p tmp
      LC_ALL=C sort -k 1,1 \
      --parallel 4 \
      --temporary-directory=tmp \
      --buffer-size=20G \
      file.tmp > "${ch_dbsnp_35_38.baseName}.bed"
      rm -r tmp
    fi
    """
}



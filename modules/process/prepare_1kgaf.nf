process extract_frequency_data {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(basefilename), path(af1kgvcf)
    //tuple basefilename, af1kgvcf from ch_file

    output:
    tuple val(basefilename), path("1kg_af_ref")
    //tuple basefilename, path("1kg_af_ref") into ch_1kg_af_ref

    script:
    """
    gendb_1kaf_extract_freq_data.sh ${af1kgvcf} "2024-09-11-1000GENOMES-phase_3.vcf" > 1kg_af_ref

    """
}

// As 1KG by default shows alternative allele frequency, we flip to follow our default on showing effect allele frequency, which in our system will be the reference allele frequency.
process flip_frequency_data {

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(basefilename), path(ref1kg)
    //tuple basefilename, ref1kg from ch_1kg_af_ref

    output:
    tuple val(basefilename), path("1kg_af_ref.flipped")
    //tuple basefilename, path("1kg_af_ref.flipped") into ch_1kg_af_ref_tosort

    script:
    """
    #sort 1kg af reference on position
    awk '{print \$1, \$2, \$3, 1-\$4, 1-\$5, 1-\$6, 1-\$7, 1-\$8}' ${ref1kg} > 1kg_af_ref.flipped
    """
}

process sort_frequency_data {

    cpus 4

    publishDir "${params.outdir}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(basefilename), path(ref1kg)
    //tuple basefilename, ref1kg from ch_1kg_af_ref_tosort

    output:
    tuple val(basefilename), path("1kg_af_ref.sorted")
    //tuple basefilename, path("1kg_af_ref.sorted") into ch_1kg_af_ref_sorted

    script:
    """
    #sort 1kg af reference on position
    LC_ALL=C sort -k 1,1 --parallel 4 ${ref1kg} > 1kg_af_ref.sorted
    """
}


process join_frequency_data_on_dbsnp_reference {

    publishDir "${params.outdir}", mode: 'copy', overwrite: true

    input:
    tuple val(basefilename), path(ref1kgsorted)
    path(ch_dbsnp_38)

    output:
    tuple val(basefilename), path("1kg_af_ref.txt")

    script:
    """
    #join the two datasets
    LC_ALL=C join -1 1 -2 1 ${ref1kgsorted} ${ch_dbsnp_38} > 1kg_af_ref.txt

    """
}

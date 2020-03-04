#!/usr/bin/env nextflow
/*
========================================================================================
                         nf-core/cleansumstats
========================================================================================
 nf-core/cleansumstats Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/nf-core/cleansumstats
----------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info nfcoreHeader()
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run nf-core/cleansumstats --infile 'gwas-sumstats.gz' -profile docker

    Mandatory arguments:
      --infile                      Path to tab-separated input data (must be surrounded with quotes)
      -profile                      Configuration profile to use. Can use multiple (comma separated)
                                    Available: conda, docker, singularity, awsbatch, test and more.

    References:                     If not specified in the configuration file or you wish to overwrite any of the references.
      --dbsnp38                     Path to dbsnp GRCh38 reference. Has to be sorted on chr:pos as first column using LC_ALL=C.
      --dbsnp37                     Path to dbsnp GRCh37 reference. Has to be sorted on chr:pos as first column using LC_ALL=C.
      --dbsnp36                     Path to dbsnp GRCh36 reference. Has to be sorted on chr:pos as first column using LC_ALL=C.
      --dbsnp35                     Path to dbsnp GRCh35 reference. Has to be sorted on chr:pos as first column using LC_ALL=C.

    Options:
      --genome                      Name of reference genome in input file


    Other options:
      --outdir                      The output directory where the results will be saved
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      --email_on_fail               Same as --email, except only send mail if the workflow is not successful
      --maxMultiqcEmailFileSize     Theshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, it will not be attached (Default: 25MB)
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    AWSBatch options:
      --awsqueue                    The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion                   The AWS Region for your AWS Batch job to run on
    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

// Check if genome exists in the config file
//if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
//    exit 1, "The provided genome '${params.genome}' is not available in the iGenomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
//}

// TODO nf-core: Add any reference files that are needed
// Configurable reference genomes
//
// NOTE - THIS IS NOT USED IN THIS PIPELINE, EXAMPLE ONLY
// If you want to use the channel below in a process, define the following:
//   input:
//   file fasta from ch_fasta
//
params.fasta = params.genome ? params.genomes[ params.genome ].fasta ?: false : false
if (params.fasta) { ch_fasta = file(params.fasta, checkIfExists: true) }

if (params.dbsnp38) { ch_dbsnp38 = file(params.dbsnp38, checkIfExists: true) }
if (params.dbsnp37) { ch_dbsnp37 = file(params.dbsnp37, checkIfExists: true) }
if (params.dbsnp36) { ch_dbsnp36 = file(params.dbsnp36, checkIfExists: true) }
if (params.dbsnp35) { ch_dbsnp35 = file(params.dbsnp35, checkIfExists: true) }

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
  custom_runName = workflow.runName
}

if ( workflow.profile == 'awsbatch') {
  // AWSBatch sanity checking
  if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
  // Check outdir paths to be S3 buckets if running on AWSBatch
  // related: https://github.com/nextflow-io/nextflow/issues/813
  if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
  // Prevent trace files to be stored on S3 since S3 does not support rolling files.
  if (workflow.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}

// Stage config files
ch_multiqc_config = file(params.multiqc_config, checkIfExists: true)
ch_output_docs = file("$baseDir/docs/output.md", checkIfExists: true)


// Header log info
log.info nfcoreHeader()
def summary = [:]
if (workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name']         = custom_runName ?: workflow.runName
summary['Input']            = params.input
if (params.dbsnp) summary['dbSNP38'] = params.dbsnp38 
if (params.dbsnp) summary['dbSNP37'] = params.dbsnp37 
if (params.dbsnp) summary['dbSNP36'] = params.dbsnp36 
if (params.dbsnp) summary['dbSNP35'] = params.dbsnp35 
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName
if (workflow.profile == 'awsbatch') {
  summary['AWS Region']     = params.awsregion
  summary['AWS Queue']      = params.awsqueue
}
summary['Config Profile'] = workflow.profile
if (params.config_profile_description) summary['Config Description'] = params.config_profile_description
if (params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if (params.config_profile_url)         summary['Config URL']         = params.config_profile_url
if (params.email || params.email_on_fail) {
  summary['E-mail Address']    = params.email
  summary['E-mail on failure'] = params.email_on_fail
  summary['MultiQC maxsize']   = params.maxMultiqcEmailFileSize
}
log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

// Check the hostnames against configured profiles
checkHostname()

def create_workflow_summary(summary) {
    def yaml_file = workDir.resolve('workflow_summary_mqc.yaml')
    yaml_file.text  = """
    id: 'nf-core-cleansumstats-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'nf-core/cleansumstats Workflow Summary'
    section_href: 'https://github.com/nf-core/cleansumstats'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
        </dl>
    """.stripIndent()

   return yaml_file
}

/*
 * Parse software version numbers
 */
process get_software_versions {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy',
        saveAs: { filename ->
            if (filename.indexOf(".csv") > 0) filename
            else null
        }

    output:
    file 'software_versions_mqc.yaml' into software_versions_yaml
    file "software_versions.csv"

    script:
    // TODO nf-core: Get all tools to print their version number here
    """
    echo $workflow.manifest.version > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    #fastqc --version > v_fastqc.txt
    #multiqc --version > v_multiqc.txt
    scrape_software_versions.py &> software_versions_mqc.yaml
    """
}

/*
 * Main pipeline starts here
 * 
 */


to_stream_sumstat_file = Channel
                .fromPath(params.input, type: 'dir')
                .map { dir -> tuple(dir.baseName, dir) }


process gunzip_sumstat_from_dir {

    //publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, sdir from to_stream_sumstat_file

    output:
    tuple datasetID, file("${datasetID}_header"), file("${datasetID}_meta") into ch_hfile_mfile
    tuple datasetID, file("${datasetID}_sfile") into ch_sfile_on_stream

    script:
    """
    cat $sdir/*.meta > ${datasetID}_meta
    zcat $sdir/*.gz > ${datasetID}_sfile
    head -n1 ${datasetID}_sfile > ${datasetID}_header
    """
}

    //extract_header_from_gzfile_in_dir.sh $sdir > ${datasetID}_header


/*
 * check validity of all col accessors from meta file
 */
process check_meta_data_format {

    //publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile from ch_hfile_mfile

    output:
    tuple datasetID, hfile, mfile into ch_mfile_ok

    script:
    """
    check_meta_data_format.sh $mfile $hfile
    """
}

ch_mfile_ok.into { ch_mfile_ok1; ch_mfile_ok2 }
ch_sfile_on_stream.into { ch_sfile_on_stream1; ch_sfile_on_stream2; ch_sfile_on_stream3; ch_sfile_on_stream4; ch_sfile_on_stream5 }
ch_mfile_and_stream=ch_mfile_ok1.join(ch_sfile_on_stream1)
ch_mfile_and_stream.into { ch_check_gb; ch_liftover;ch_stats_inference }

//process filter_location_format {
//
//    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true
//
//    input:
//    tuple datasetID, hfile, mfile, sfile from ch_check_gb
//
//    
//    output:
//    tuple datasetID, hfile, mfile, file("location_format_filtered") into ch_location_filtered
//
//    script:
//    """
//    filter_location_format.sh $sfile > location_format_filtered
//
//    """
//}



whichbuild = ['GRCh35', 'GRCh36', 'GRCh37', 'GRCh38']

process genome_build_stats {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, sfile from ch_check_gb
    each build from whichbuild

    output:
    tuple datasetID, file("${datasetID}*.res") into ch_genome_build_stats

    script:
    """
    format_for_chrpos_join.sh $sfile $mfile > tmp


    colCHR=\$(grep "^colCHR=" ${mfile})
    colCHR="\${colCHR#*=}"
    colPOS=\$(grep "^colPOS=" ${mfile})
    colPOS="\${colPOS#*=}"
                                                                                                                                                  
    head -n10000 ${sfile} | sstools-utils ad-hoc-do -k "0|\${colCHR}|\${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print \$2":"\$3,\$1}' > gb_lift
    LC_ALL=C sort -k1,1 gb_lift > gb_lift_sorted
    format_chrpos_for_dbsnp.sh ${build} gb_lift_sorted ${ch_dbsnp35} ${ch_dbsnp36} ${ch_dbsnp37} ${ch_dbsnp38} > ${build}.map
    sort -u -k1,1 ${build}.map | wc -l | awk -vOFS="\t" -vbuild=${build} '{print \$1,build}' > ${datasetID}.${build}.res
    """
}

 //   liftover_file_from_to.sh tmp ${build} "GRCh38" 1000 > ${build}
 //   LC_ALL=C sort -k1,1 ${build} > ${build}.sorted
 //   LC_ALL=C join -t "\$(printf '\t')" -o 1.1 1.2 2.2 2.3 2.4 -1 1 -2 1 ${build}.sorted ${ch_dbsnp38} > ${build}.sorted.join
 //   sort -u -k1,1 ${build}.sorted.join | wc -l | awk -vOFS="\t" -vbuild=${build} '{print \$1,build}' > ${build}.${datasetID}.res


ch_genome_build_stats_grouped = ch_genome_build_stats.groupTuple(by:0,size:4)

process infer_genome_build {

    //publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, file(ujoins) from ch_genome_build_stats_grouped

    
    output:
    tuple datasetID, env(GRChmax) into ch_known_genome_build
    tuple datasetID, file("${datasetID}.stats") into ch_stats_genome_build

    script:
    """
    for gbuild in ${ujoins}
    do
        cat \$gbuild >> ${datasetID}.stats
    done
    GRChmax="\$(cat ${datasetID}.stats | sort -r -k1,1 | head -n1 | awk '{print \$2}')"
    """

}

ch_liftover_2=ch_liftover.join(ch_known_genome_build)

process prep_dbsnp_mapling_by_sorting_chrpos {
    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, sfile, gbmax from ch_liftover_2

    output:
    tuple datasetID, hfile, mfile, file("gb_lift_sorted"), gbmax into ch_liftover_3

    script:
    """
    
    colCHR=\$(grep "^colCHR=" ${mfile})
    colCHR="\${colCHR#*=}"
    colPOS=\$(grep "^colPOS=" ${mfile})
    colPOS="\${colPOS#*=}"

    cat ${sfile} | sstools-utils ad-hoc-do -k "0|\${colCHR}|\${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print \$2":"\$3,\$1}' > gb_lift
    LC_ALL=C sort -k1,1 gb_lift > gb_lift_sorted
    """

}

process liftover_and_map_to_dbsnp38 {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, fsorted, gbmax from ch_liftover_3
    
    output:
    tuple datasetID, hfile, mfile, file("gb_liftgr38") into ch_liftover_4

    script:
    """
    format_chrpos_for_dbsnp.sh ${gbmax} ${fsorted} ${ch_dbsnp35} ${ch_dbsnp36} ${ch_dbsnp37} ${ch_dbsnp38} > gb_liftgr38
    """
}

process sort_new_dbsnp38map {
    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, mapped from ch_liftover_4
    
    output:
    tuple datasetID, hfile, mfile, file("gb_liftgr38_sorted") into ch_liftover_5

    script:
    """
    LC_ALL=C sort -k1,1 $mapped > gb_liftgr38_sorted
    """

}

process liftover_and_map_to_rsids_and_alleles {
    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, gb_liftgr38_sorted from ch_liftover_5
    
    output:
    tuple datasetID, val("GRCh38"), hfile, mfile, file("gb_ready_liftgr38") into ch_mapped_GRCh38
    tuple datasetID, val("GRCh37"), hfile, mfile, file("gb_ready_liftgr37") into ch_mapped_GRCh37

    script:
    """
    LC_ALL=C join -1 1 -2 1 $gb_liftgr38_sorted ${ch_dbsnp38} | awk -vFS="[[:space:]]" -vOFS="\t" '{print \$2,\$6,\$7,\$8,\$9}' > gb_ready_liftgr37
    awk -vFS="[[:space:]]" -vOFS="\t" '{print \$2,\$1,\$3,\$4,\$5}' $gb_liftgr38_sorted > gb_ready_liftgr38
    """
}


////    //format_for_chrpos_join.sh $sfile $mfile | liftover_file_from_to.sh - "GRCh37" "GRCh38" "all" > GRCh38
////
//ch_mapped_data.into { ch_mapped_GRCh38; ch_mapped_GRCh37_pre }
//
//process liftback_to_GRCh37 {
//
//    //publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true
//
//    input:
//    tuple datasetID, build, hfile, mfile, liftgr38, gbmax from ch_mapped_GRCh37_pre
//    
//
//    script:
//    """
//    
//    """
//}


ch_mapped_data_mix=ch_mapped_GRCh38.mix(ch_mapped_GRCh37)

process split_multiallelics_and_resort_index {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, build, hfile, mfile, liftgrs from ch_mapped_data_mix
    
    output:
    tuple datasetID, build, hfile, mfile, file("${datasetID}_${build}_mapped") into ch_allele_correction

    script:
    """
    split_multiallelics_to_rows.sh $liftgrs > liftgrs2
    echo -e "0\tCHRPOS\tRSID\tA1\tA2" > ${datasetID}_${build}_mapped
    LC_ALL=C sort -k1,1 liftgrs2 >> ${datasetID}_${build}_mapped
    """
}

ch_allele_correction_combine=ch_allele_correction.combine(ch_sfile_on_stream2, by: 0)
ch_allele_correction_combine.into{ ch_allele_correction_combine1; ch_allele_correction_combine2 }

process does_exist_A2 {

    input:
    tuple datasetID, hfile, mfile from ch_mfile_ok2
    
    output:
    tuple datasetID, env(A2exists) into ch_present_A2

    script:
    """
    A2exists=\$(doesA2exist.sh $mfile)
    """
}

//Create filter for when A2 exists or not
ch_present_A2_br=ch_present_A2.branch { key, value -> 
                A2exists: value == "true"
                A2missing: value == "false"
                }

//split the channels based on filter
ch_present_A2_br2=ch_present_A2_br.A2exists
ch_present_A2_br3=ch_present_A2_br.A2missing

//combine each channel with the matching datasetID
ch_A2_exists=ch_allele_correction_combine1.combine(ch_present_A2_br2, by: 0)
ch_A2_missing=ch_allele_correction_combine2.combine(ch_present_A2_br3, by: 0)

process allele_correction_A1_A2 {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, build, hfile, mfile, mapped, sfile, A2exists from ch_A2_exists
    
    output:
    tuple datasetID, build, hfile, mfile, file("${build}_acorrected") into ch_A2_exists2

    script:
    """
    echo -e "0\tA1\tA2\tCHRPOS\tRSID\tB1\tB2\tEMOD" > ${build}_acorrected
    allele_correction_wrapper.sh $sfile $mapped $mfile "A2exists" >> ${build}_acorrected
    """
}
    //tuple datasetID, file("disc*") into placeholder2

process allele_correction_A1 {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, build, hfile, mfile, mapped, sfile, A2missing from ch_A2_missing
    
    output:
    tuple datasetID, build, hfile, mfile, file("${build}_acorrected") into ch_A2_missing2
    file("${build}_mapped2") into placeholder4

    script:
    """
    multiallelic_filter.sh $mapped > ${build}_mapped2
    echo -e "0\tA1\tA2\tCHRPOS\tRSID\tB1\tB2\tEMOD" > ${build}_acorrected
    allele_correction_wrapper.sh $sfile ${build}_mapped2 $mfile "A2missing" >> ${build}_acorrected 
    """
}

//mix channels
ch_allele_corrected_mix=ch_A2_exists2.mix(ch_A2_missing2)
ch_allele_corrected_mix.into{ ch_allele_corrected_mix1; ch_allele_corrected_mix2 }


process filter_stats {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, sfile from ch_stats_inference
    
    output:
    tuple datasetID, hfile, mfile, file("st_filtered") into ch_stats_inference2
    tuple datasetID, file("st_error")  into placeholder2

    script:
    """
    filter_stat_values.sh $mfile $sfile > st_filtered 2> st_error 
    """
}


process infer_stats {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, st_filtered from ch_stats_inference2
    
    output:
    tuple datasetID, hfile, mfile, file("st_inferred_stats") into ch_stats_selection

    script:
    """
    check_stat_inference.sh $mfile > st_which_to_do
    nh="\$(awk '{printf "%s,", \$1}' st_which_to_do | sed 's/,\$//' )"
    nf="\$(awk '{printf "%s|", \$2}' st_which_to_do | sed 's/|\$//' )"
    cat $st_filtered | sstools-utils ad-hoc-do -f - -k "0|\${nf}" -n"0,\${nh}" > st_inferred_stats
    """
}

ch_stats_selection2=ch_stats_selection.combine(ch_sfile_on_stream4, by: 0)

process select_stats {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, hfile, mfile, inferred, sfile from ch_stats_selection2
    
    output:
    tuple datasetID, file("st_stats_for_output") into ch_stats_for_output

    script:
    """
    select_stats_for_output.sh $mfile $sfile $inferred > st_stats_for_output
    """
}

ch_allele_corrected_and_outstats=ch_allele_corrected_mix1.combine(ch_stats_for_output, by: 0)

process final_assembly {

    publishDir "${params.outdir}/$datasetID", mode: 'symlink', overwrite: true

    input:
    tuple datasetID, build, hfile, mfile, acorrected, stats from ch_allele_corrected_and_outstats
    
    output:
    file("${datasetID}_${build}_cleaned") into ch_end

    script:
    """
    apply_modifier_on_stats.sh $acorrected $stats > ${datasetID}_${build}_cleaned
    """
}



/*
 * Completion e-mail notification
 */
workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[nf-core/cleansumstats] Successful: $workflow.runName"
    if (!workflow.success) {
      subject = "[nf-core/cleansumstats] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if (workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if (workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if (workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    if (workflow.container) email_fields['summary']['Docker image'] = workflow.container
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // Check if we are only sending emails on failure
    email_address = params.email
    if (!params.email && params.email_on_fail && !workflow.success) {
        email_address = params.email_on_fail
    }

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: email_address, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.maxMultiqcEmailFileSize.toBytes() ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (email_address) {
        try {
          if ( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
          // Try to send HTML e-mail using sendmail
          [ 'sendmail', '-t' ].execute() << sendmail_html
          log.info "[nf-core/cleansumstats] Sent summary e-mail to $email_address (sendmail)"
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, email_address ].execute() << email_txt
          log.info "[nf-core/cleansumstats] Sent summary e-mail to $email_address (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File( "${params.outdir}/pipeline_info/" )
    if (!output_d.exists()) {
      output_d.mkdirs()
    }
    def output_hf = new File( output_d, "pipeline_report.html" )
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_txt }

    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
      log.info "${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}"
      log.info "${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}"
      log.info "${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}"
    }

    if (workflow.success) {
        log.info "${c_purple}[nf-core/cleansumstats]${c_green} Pipeline completed successfully${c_reset}"
    } else {
        checkHostname()
        log.info "${c_purple}[nf-core/cleansumstats]${c_red} Pipeline completed with errors${c_reset}"
    }

}


def nfcoreHeader(){
    // Log colors ANSI codes
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";

    return """    -${c_dim}--------------------------------------------------${c_reset}-
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  nf-core/cleansumstats v${workflow.manifest.version}${c_reset}
    -${c_dim}--------------------------------------------------${c_reset}-
    """.stripIndent()
}

def checkHostname(){
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}

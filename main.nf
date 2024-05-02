#!/usr/bin/env nextflow
// -*- mode: groovy; -*-
/*
vim: syntax=groovy

========================================================================================
                         cleansumstats
========================================================================================
cleansumstats Pipeline.
 #### Homepage / Documentation
 https://github.com/BioPsyk/cleansumstats
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

pipelineVersion = new File("$projectDir/VERSION").text.trim()

def helpMessage() {
    log.info nfcoreHeader()
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run cleansumstats --input 'gwas_sumstats_meta_file.txt' -profile singularity

    Mandatory arguments:
      --input                       Path to metadata file in YAML format

    References:                     If not set here, it has to be specified in the configuration file
      --dbsnp_38                    Path to dbsnp GRCh38 reference
      --dbsnp_38_37                 Path to dbsnp GRCh38 to GRCh37 map reference
      --dbsnp_37_38                 Path to dbsnp GRCh37 to GRCh38 map reference
      --dbsnp_36_38                 Path to dbsnp GRCh36 to GRCh38 map reference
      --dbsnp_35_38                 Path to dbsnp GRCh35 to GRCh38 map reference
      --dbsnp_RSID_38               Path to dbsnp RSID to GRCh38 map reference

    Options:
      --placeholderOption           Generates a meta file template, which is one of the required inputs to the cleansumstats pipeline

    Filtering:
      --beforeLiftoverFilter        A comma separated list ordered by filtering exclusion order including any of the following:
                                      duplicated_keys
                                    Example(default): --beforeLiftoverFilter duplicated_keys


      --afterAlleleCorrectionFilter A comma separated list ordered by filtering exclusion order including any of the following:
                                      duplicated_chrpos_in_GRCh37
                                    Example(default): --afterAlleleCorrectionFilter duplicated_chrpos_in_GRCh37

    Auxiliaries:
      --generateMetafile            Generates a meta file template, which is one of the required inputs to the cleansumstats pipeline

      --generateDbSNPreference      Generates a meta file template, which is one of the required inputs to the cleansumstats pipeline
      --hg38ToHg19chain             chain file used for liftover (required for --generateDbSNPreference)
      --hg19ToHg18chain             chain file used for liftover (required for --generateDbSNPreference)
      --hg19ToHg17chain             chain file used for liftover (required for --generateDbSNPreference)

    Other options:
      --outdir                      The output directory where the results will be saved
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      --email_on_fail               Same as --email, except only send mail if the workflow is not successful
      --maxMultiqcEmailFileSize     Theshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, it will not be attached (Default: 25MB)
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    Debug:
      --keepIntermediateFiles       Keeps intermediate files, useful for debugging

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

// checker only
if(params.checkonly){
  doCompleteCleaningWorkflow = false
}else{
  doCompleteCleaningWorkflow = true
}

// check filter
beforeLiftoverFilter = params.beforeLiftoverFilter
//afterLiftoverFilter = params.afterLiftoverFilter
afterAlleleCorrectionFilter = params.afterAlleleCorrectionFilter

// Set channels
if (params.generateDbSNPreference) {
  if (params.hg38ToHg19chain) { ch_hg38ToHg19chain = file(params.hg38ToHg19chain, checkIfExists: true) }
  if (params.hg19ToHg18chain) { ch_hg19ToHg18chain = file(params.hg19ToHg18chain, checkIfExists: true) }
  if (params.hg19ToHg17chain) { ch_hg19ToHg17chain = file(params.hg19ToHg17chain, checkIfExists: true) }

  if (params.dbsnp_38) { ch_dbsnp_38 = file(params.dbsnp_38) }
  if (params.dbsnp_38_37) { ch_dbsnp_38_37 = file(params.dbsnp_38_37) }
  if (params.dbsnp_37_38) { ch_dbsnp_37_38 = file(params.dbsnp_37_38) }
  if (params.dbsnp_36_38) { ch_dbsnp_36_38 = file(params.dbsnp_36_38) }
  if (params.dbsnp_35_38) { ch_dbsnp_35_38 = file(params.dbsnp_35_38) }
  if (params.dbsnp_RSID_38) { ch_dbsnp_RSID_38 = file(params.dbsnp_RSID_38) }
}else if(params.generate1KgAfSNPreference){

  if (params.dbsnp_38) { ch_dbsnp_38 = file(params.dbsnp_38, checkIfExists: true) }
  if (params.dbsnp_38_37) { ch_dbsnp_38_37 = file(params.dbsnp_38_37, checkIfExists: true) }
  if (params.dbsnp_37_38) { ch_dbsnp_37_38 = file(params.dbsnp_37_38, checkIfExists: true) }
  if (params.dbsnp_36_38) { ch_dbsnp_36_38 = file(params.dbsnp_36_38, checkIfExists: true) }
  if (params.dbsnp_35_38) { ch_dbsnp_35_38 = file(params.dbsnp_35_38, checkIfExists: true) }
  if (params.dbsnp_RSID_38) { ch_dbsnp_RSID_38 = file(params.dbsnp_RSID_38, checkIfExists: true) }

}else {

  if (params.kg1000AFGRCh38) { ch_kg1000AFGRCh38 = file(params.kg1000AFGRCh38, checkIfExists: true) }
  if (params.dbsnp_38) { ch_dbsnp_38 = file(params.dbsnp_38, checkIfExists: true) }
  if (params.dbsnp_38_37) { ch_dbsnp_38_37 = file(params.dbsnp_38_37, checkIfExists: true) }
  if (params.dbsnp_37_38) { ch_dbsnp_37_38 = file(params.dbsnp_37_38, checkIfExists: true) }
  if (params.dbsnp_36_38) { ch_dbsnp_36_38 = file(params.dbsnp_36_38, checkIfExists: true) }
  if (params.dbsnp_35_38) { ch_dbsnp_35_38 = file(params.dbsnp_35_38, checkIfExists: true) }
  if (params.dbsnp_RSID_38) { ch_dbsnp_RSID_38 = file(params.dbsnp_RSID_38, checkIfExists: true) }
}

params.ch_regexp_lexicon = file("$baseDir/assets/map_regexp_and_adhocfunction.txt", checkIfExists: true)

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
  custom_runName = workflow.runName
}



// Header log info
log.info cleansumstatsHeader()
def summary = [:]
if (workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name']         = custom_runName ?: workflow.runName
summary['Input']            = params.input
//if (params.dbsnp38) summary['dbSNP38'] = params.dbsnp38
//if (params.dbsnp37) summary['dbSNP37'] = params.dbsnp37
//if (params.dbsnp36) summary['dbSNP36'] = params.dbsnp36
//if (params.dbsnp35) summary['dbSNP35'] = params.dbsnp35
//if (params.dbsnpRSID) summary['dbsnpRSID'] = params.dbsnpRSID

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
log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

// Check the hostnames against configured profiles
//checkHostname()

def create_workflow_summary(summary) {
    def yaml_file = workDir.resolve('workflow_summary_mqc.yaml')
    yaml_file.text  = """
    id: 'cleansumstats-summary'
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


process get_software_versions {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy', overwrite: true, pattern: '*.csv'

    output:
    file "software_versions" into ch_software_versions


    script:
    """
    echo $pipelineVersion > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    sstools-version > v_sumstattools.txt
    echo "placeholder" > software_versions
    """
}

import dk.biopsyk.PipelineSession

def sess = new PipelineSession<Metadata>(
  Metadata.class,
  baseDir,
  workflow.workDir,
  params
)

params.sess=sess

include { prepare_dbsnp_reference } from './modules/subworkflow/prepare_dbsnp.nf'
include { prepare_1kgaf_reference } from './modules/subworkflow/prepare_1kgaf.nf'

include { main_init_checks_crucial_paths } from './modules/subworkflow/main_init_checks_crucial_paths.nf'
include {
  calculate_checksum_on_metafile_input
  make_metafile_unix_friendly
  calculate_checksum_on_sumstat_input
  check_sumstat_format
  add_sorted_rowindex_to_sumstat
} from './modules/process/main_init_checks.nf'

include { map_to_dbsnp } from './modules/subworkflow/map_to_dbsnp.nf'
include { allele_correction } from './modules/subworkflow/allele_correction.nf'
include { update_stats } from './modules/subworkflow/update_stats.nf'
include { organize_output } from './modules/subworkflow/organize_output.nf'

workflow {
  main:

  if (params.generateMetafile){
    sess.metadata_paths.each {
      log.info "Writing metadata template"

      def metadata_id = it.getBaseName().toString()

      def template_file = new File("${params.outdir}/${metadata_id}.template.yaml")
      template_file.write(
        sess.metadata_schema.generate_metadata_template()
      )

      log.info "Metadata template written to ${params.outdir}/${metadata_id}.template.yaml"
    }
  }else if(params.generateMetaClass){
    log.info "Metadata class written to ${params.outdir}/Metadata.groovy"

    def class_file = new File("${params.outdir}/Metadata.groovy")
    class_file.write(
      sess.metadata_schema.generate_metadata_groovy_class()
    )

    log.info "Metadata class written to ${params.outdir}/Metadata.groovy"
  }else if(params.generateDbSNPreference){
    prepare_dbsnp_reference("${params.input}")
  }else if(params.generate1KgAfSNPreference){
    prepare_1kgaf_reference("${params.input}", ch_dbsnp_38)
    //#check for not agreeing ref alleles and alt alleles
    // awk '{if($2!=$10){print $0}}' 1kg_af_ref.sorted.joined | head
    // awk '{if($3!=$11){print $0}}' 1kg_af_ref.sorted.joined | head
  }else {

    //=================================================================================
    // Pre-execution validation
    //=================================================================================

    log.info("Reading metadata files")

    sess.read_metadata_files()

    log.info("All metadata files read")
    log.info("Validating pipeline parameters")

    ParametersValidator.validate_filters_allowed(
      "before",
      params.beforeLiftoverFilter,
      "${baseDir}/assets/allowed_names_beforeLiftoverFilter.txt"
    )

  //  ParametersValidator.validate_filters_allowed(
  //    "after",
  //    params.afterLiftoverFilter,
  //    "${baseDir}/assets/allowed_names_afterLiftoverFilter.txt"
  //  )

    log.info("All pipeline parameters validated")


    //=================================================================================
    // Start of execution
    //=================================================================================

    Channel
      .fromPath("${params.input}", type: 'file')
      .map { file -> tuple(file.baseName, file) }
      .set { ch_mfile_checkX }

    main_init_checks_crucial_paths(ch_mfile_checkX, sess)
    calculate_checksum_on_metafile_input(ch_mfile_checkX)
    calculate_checksum_on_sumstat_input(main_init_checks_crucial_paths.out.spath)
    make_metafile_unix_friendly(ch_mfile_checkX)
    check_sumstat_format(main_init_checks_crucial_paths.out.mfile_check_format)
    add_sorted_rowindex_to_sumstat(check_sumstat_format.out.sfile)

    if (doCompleteCleaningWorkflow){

      map_to_dbsnp(add_sorted_rowindex_to_sumstat.out.main)
      ch_allele_correction_combine=map_to_dbsnp.out.dbsnp_mapped.join(add_sorted_rowindex_to_sumstat.out.main, by: 0)
      allele_correction(ch_allele_correction_combine)
      update_stats(add_sorted_rowindex_to_sumstat.out.main, allele_correction.out.allele_corrected)

      //Collect and place in corresponding stepwise order
      map_to_dbsnp.out.dbsnp_rm_ix
       .join(allele_correction.out.removed_by_allele_filter_ix, by: 0)
       .join(update_stats.out.stats_rm_by_filter_ix, by: 0)
       .set{ ch_collected_removed_lines }

      //Collect desc_BA info
      check_sumstat_format.out.nrows_before_after
      .join(add_sorted_rowindex_to_sumstat.out.nrows_before_after, by: 0)
      .join(map_to_dbsnp.out.rows_before_after)
      .join(allele_correction.out.desc_filt_allele_pairs_BA)
      .join(update_stats.out.nrows_before_after)
      .set {nrows_before_after}


      //join checksums
      calculate_checksum_on_metafile_input.out.main
      .join(calculate_checksum_on_sumstat_input.out.main, by: 0)
      .set { ch_mfile_cleaned_x }


      map_to_dbsnp.out.ch_gb_stats_combined
      .join(update_stats.out.cleaned_stats_col_source, by: 0)
      .set{ ch_to_write_to_filelibrary7 }

      //for raw output
      main_init_checks_crucial_paths.out.rpath
      .join(main_init_checks_crucial_paths.out.pdfstuff, by: 0)
      .set{ ch_to_write_to_raw }

      organize_output(
        allele_correction.out.allele_corrected,
        update_stats.out.cleaned_stats,
        ch_collected_removed_lines,
        main_init_checks_crucial_paths.out.spath,
        add_sorted_rowindex_to_sumstat.out.main,
        nrows_before_after,
        ch_mfile_cleaned_x,
        ch_to_write_to_filelibrary7,
        ch_mfile_checkX,
        ch_to_write_to_raw
      )
    }
  }
}


def cleansumstatsHeader(){
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
                                            ${c_cyan}`._,._,\'${c_reset}
    ${c_purple} cleansumstats v${pipelineVersion}${c_reset}
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

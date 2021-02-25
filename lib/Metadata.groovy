import groovy.lang.MetaProperty
import java.nio.file.Path
import java.nio.file.Paths
import dk.biopsyk.BaseMetadata

/**
 * Represents the contents of a metadata YAML-file. Contains functionality to:
 *
 * - Parse metadata files
 * - Validate paths that the metadata file points to
 * - Utilities for extracting commonly used metadata
 */
class Metadata extends BaseMetadata {
  // WARNING: All members of this class has been autogenerated from the json-schema file.
  // All changes to member names and types should be done in the json-schema. Then a new
  // groovy class should be generated by running the pipeline with the `--generateMetafile`
  // flag. Finally copy all members from the file `${params.outdir}/Metadata.groovy`.
  String cleansumstats_version = null
  String cleansumstats_metafile_user = null
  Date cleansumstats_metafile_date = null
  String path_sumStats = null
  String path_readMe = null
  String path_pdf = null
  List<String> path_supplementary = []
  String study_Title = null
  String study_PMID = null
  int study_Year = 0
  String study_PhenoDesc = null
  List<String> study_PhenoCode = []
  String study_FilePortal = null
  String study_FileURL = null
  String study_AccessDate = null
  String study_Use = null
  String study_Controller = null
  String study_Contact = null
  String study_Restrictions = null
  String study_includedCohorts = null
  String study_Ancestry = null
  String study_Gender = null
  String study_PhasePanel = null
  String study_PhaseSoftware = null
  String study_ImputePanel = null
  String study_ImputeSoftware = null
  String study_Array = null
  String study_Notes = null
  String stats_TraitType = null
  String stats_Model = null
  int stats_TotalN = 0
  int stats_CaseN = 0
  int stats_ControlN = 0
  String stats_GCMethod = null
  float stats_GCValue = 0.0
  String stats_Notes = null
  String col_CHR = null
  String col_POS = null
  String col_SNP = null
  String col_EffectAllele = null
  String col_OtherAllele = null
  String col_BETA = null
  String col_SE = null
  String col_OR = null
  String col_ORL95 = null
  String col_ORU95 = null
  String col_Z = null
  String col_P = null
  String col_N = null
  String col_CaseN = null
  String col_ControlN = null
  String col_AFREQ = null
  String col_INFO = null
  String col_EAF = null
  String col_OAF = null
  String col_Direction = null
  String col_Notes = null
  // End of auto-generated code

  /**
   *
   */
  public def postprocess() {
    System.out.println("Postprocess metadata")

    this.validate_paths()
    this.validate_sumstat_header()
  }

  /**
   * Makes sure that all metadata fields that are paths points to an existing and readable file.
   */
  private def validate_paths() {
    Metadata.class.metaClass.getProperties().each { prop ->
      if (!prop.name.startsWith("path_")) return

      def value = Metadata.class.metaClass.getProperty(this, prop.name)

      if (value == null) {
        return
      } else if (value instanceof String) {
        value = assert_readable_file_exists(prop.name, value)
      } else if (value instanceof List) {
        value = value.collect {
          assert_readable_file_exists(prop.name, it)
        }
      } else {
        return
      }

      Metadata.class.metaClass.setProperty(this, prop.name, value)
    }
  }


  private def validate_sumstat_header() {
    def header = new SumstatHeader(this.path_sumStats)

    Metadata.class.metaClass.getProperties().each { prop ->
      if (!prop.name.startsWith("col_")) return

      def column_name = Metadata.class.metaClass.getProperty(this, prop.name)

      if (column_name == null) return

      if (!header.column_exists(column_name)) {
        throw new Exception(
          "Column '${column_name}' (from metadata field '${prop.name}') did not exist in sumstat file header: ${header.columns}"
        )
      }
    }
  }

  /**
   * Shortcut for checking the both CHR and POS column exists in the metadata.
   *
   * @returns True when both exists, false otherwise.
   */
  public def chrpos_exists() {
    return this.col_CHR && this.col_POS
  }

  /**
   * Shortcut for checking if the CHR and POS columns points to the SNP column.
   *
   * @returns True if both CHR and POS points to the SNP column.
   */
  public def chrpos_points_to_snp() {
    return this.col_CHR == this.col_SNP && this.col_POS == this.col_SNP
  }

  /**
   * Shortcut for getting all the stat field values as a map, with EAF adjusted based
   * on given allele frequency branch.
   *
   * @returns Map of all stat fields resolved.
   */
  public def resolve_stat_fields() {
    def stats = [
      "BETA": this.col_BETA,
      "SE": this.col_SE,
      "Z": this.col_Z,
      "P": this.col_P,
      "OR": this.col_OR,
      "ORL95": this.col_ORL95,
      "ORU95": this.col_ORU95,
      "N": this.col_N,
      "CaseN": this.col_CaseN,
      "ControlN": this.col_ControlN,
      "EAF": this.col_EAF,
      "OAF": this.col_OAF,
      "INFO": this.col_INFO
    ]

    return stats.findAll { it.value != null }
  }

  /**
   * Gets the inference functions that can be used with r-stat-c-streamer based
   * on which stat columns are available in the sumstats file.
   *
   * @param stat_fields The resolved stat fields to check.
   * @see Metadata.resolve_stat_fields For details on how the stat fields are resolved.
   * @returns List of r-stat-c-streamer inference functions that can be used.
   */
  public def get_inference_functions(Map stat_fields) {
    if (this.stats_Model != "linear") {
      return []
    }

    def funcs = [:]

    funcs["zscore_from_beta_se"] = ["BETA", "SE"]
    funcs["zscore_from_pval_beta"] = ["BETA", "P"]
    funcs["zscore_from_pval_beta_N"] = ["BETA", "P", "N"]
    funcs["pval_from_zscore"] = ["Z"]
    funcs["pval_from_zscore_N"] = ["Z", "N"]
    funcs["beta_from_zscore_se"] = ["Z", "SE"]
    funcs["beta_from_zscore_N_af"] = ["Z", "N", "EAF"]
    funcs["se_from_zscore_beta"] = ["Z", "BETA"]
    funcs["se_from_zscore_n_af"] = ["Z", "N", "EAF"]
    funcs["N_from_zscore_beta_af"] = ["Z", "BETA", "EAF"]

    def result = []

    funcs.each { func ->
      if (func.value.every { stat_fields[it] != null }) {
        result.add(func.key)
      }
    }

    return result
  }

  /**
   * Gets the inference names that can be used with sumstat-tools based
   * on which stat columns are available in the sumstats file.
   *
   * @param stat_fields The resolved stat fields to check.
   * @see Metadata.resolve_stat_fields For details on how the stat fields are resolved.
   * @returns Map of field names where the values are the inference names.
   */
  public def get_inference_names(Map stat_fields) {
    def stat_names = [
      "BETA": "beta",
      "SE": "standarderror",
      "Z": "zscore",
      "P": "pvalue",
      "OR": "oddsratio",
      "N": "Nindividuals",
      "EAF": "allelefreq"
    ]

    def result = []

    stat_names.each {
      if (stat_fields[it.key]) {
        result.add(it.value)
      }
    }

    return result
  }

  /**
   * Gets the inference arguments for r-stat-c-streamer based
   * on which stat columns are available in the sumstats file.
   *
   * @param stat_fields The resolved stat fields to check.
   * @see Metadata.resolve_stat_fields For details on how the stat fields are resolved.
   * @returns List of arguments as string in the format "--{{ name }} {{ index }}".
   */
  public def get_inference_arguments(List names) {
    def result = ["--index 1"]
    def index = 1

    names.each {
      index++

      result.add("--${it} ${index}")
    }

    return result
  }
}

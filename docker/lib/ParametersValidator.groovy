/**
 * Helper class that contains validation functionality for different types of Nextflow parameters.
 */
class ParametersValidator {

  /**
   * Makes sure that the given "*LiftoverFilter" parameter only contains filters that are allowed.
   * Available prefixes are "before" and "after" (replaces the * in the parameter name above).
   *
   * @param prefix           Prefix to use in error message when validation fails.
   * @param filters_literal  The actual value of the parameter that is being validated.
   * @param lookup_file_path Path to the file that contains the allowed filters.
   * @throws Exception       When a filter is supplied that is not allowed.
   */
  static def validate_filters_allowed(String prefix, String filters_literal, String lookup_file_path) {
    Set filters = filters_literal.tokenize(',')
    Set allowed_filters = new File(lookup_file_path).getText('UTF-8').tokenize('\n')
    Set not_allowed_filters = filters.minus(allowed_filters)

    if (!not_allowed_filters.isEmpty()) {
      throw new Exception("Provided ${prefix} filters are not allowed: ${not_allowed_filters}")
    }
  }
}

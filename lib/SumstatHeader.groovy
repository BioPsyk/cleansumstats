/**
 * Represents the header of a sumstats file, read and parsed.
 */
class SumstatHeader {
  String sumstat_path = null
  List columns = null

  /**
   * Reads the header of a gzipped sumstats file, parses the column names and returns a
   * new instance of the SumstatHeader class.
   *
   * @param sumstat_path Path to the sumstat file to read, can be relative or absolute.
   */
  SumstatHeader(String sumstat_path) {
    if (!sumstat_path.endsWith(".gz")) {
      throw new Exception("Path to sumstat file did not have .gz extension: ${sumstat_path}")
    }

    def first_line = [
      "bash", "-c", "zcat ${sumstat_path} | head -n 1"
    ].execute().text

    this.columns = first_line.tokenize('\t')
    this.sumstat_path = sumstat_path
  }

  /**
   * Shortcut for checking if a column of the given name exists in the header.
   *
   * @param column Column name as it appears in the sumstat files header.
   * @returns True when found, false otherwise.
   */
  public def column_exists(String column) {
    return (this.columns).find { it == column }
  }
}

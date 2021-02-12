import java.nio.file.FileSystems
import java.nio.file.Paths
import sun.nio.fs.UnixPath

/**
 * Represents a single pipeline session, meaning a single pipeline execution.
 * Note that a single session can consist of multiple metadata files.
 */
class PipelineSession {
  String pipeline_directory = null
  String working_directory = null
  MetadataSchema metadata_schema = null
  List<String> metadata_paths = []
  Map<String, Metadata> metadata_instances = [:]

  /**
   * Loads the raw metadata schema from the assets directory, resolves all the metadata
   * paths given in the input parameter and returns a Session instance.
   *
   * @param pipeline_directory Directory where the pipeline code lives.
   * @param working_directory Directory where the pipeline is executed.
   * @param input_path Path to the metadata file(s) to process.
   */
  PipelineSession(UnixPath pipeline_directory, UnixPath working_directory, String input_path) {
    this.pipeline_directory = pipeline_directory
    this.working_directory = working_directory
    this.metadata_schema = new MetadataSchema("${pipeline_directory}/assets/schemas/raw-metadata.yaml")
    this.resolve_input_path(input_path)
  }

  /**
   * Resolves input path glob pattern as a list of metadata file paths. If the
   * input path is not a glob pattern a list with a single aboslute metadata
   * path is produced instead.
   *
   * Note: terminates the pipeline when errors are encountered instead of throwing an
   * exception.
   *
   * @param input_path File path or glob pattern of metadata file(s).
   */
  def resolve_input_path(String input_path) {
    List<String> input_parts = input_path.tokenize("*")

    if (input_path[0] == "*") {
      input_parts = [this.working_directory, input_path]
    } else if (input_parts.size == 1) {
      this.metadata_paths.add(
        Paths.get(input_path).toAbsolutePath()
      )

      return
    } else if (input_parts.size > 2) {
      System.err.println("Handling glob patterns with more than one * is not implemented: '${input_path}'")
      System.exit(1)
    }

    def metadata_directory = input_parts[0]
    def metadata_name = "*${input_parts[1]}"
    def matcher = FileSystems.getDefault().getPathMatcher("glob:${metadata_name}");

    new File(metadata_directory).traverse(type: groovy.io.FileType.FILES, maxDepth: 0) {
      def metadata_path = Paths.get(it.name)

      if(!matcher.matches(metadata_path)) return

      this.metadata_paths.add(Paths.get(metadata_directory, it.name))
    }

    if (!metadata_paths) {
      System.err.println("No metadata files found using glob pattern: ${input_path}")
      System.exit(1)
    }
  }

  /**
   * Reads and validates all metadata files from the list of metadata paths.
   *
   * Note: terminates the pipeline when errors are encountered instead of throwing an
   * exception.
   */
  def read_metadata_files() {
    this.metadata_paths.each {
      def metadata = null

      try {
        metadata = this.metadata_schema.read_metadata_file(it)
        metadata.validate_paths()

        this.metadata_instances[it.getBaseName().toString()] = metadata
      } catch(Exception e) {
        System.err.println("Failed to read/validate metadata file ${it}: ${e.message}")
        System.exit(1)
      }

      def sumstat_header = new SumstatHeader(metadata.path_sumStats)

      try {
        metadata.validate_sumstat_header(sumstat_header)
      } catch (Exception e) {
        System.err.println("Sumstat '${metadata.path_sumStats}' header validation failed: ${e.message}")
        System.exit(1)
      }

      System.err.println("Successfully read/validated metadata file '${it}'")
    }
  }

  /**
   * Retrieves the metadata instance of the given key, if not found will terminate the pipeline
   * with an error.
   */
  def get_metadata(String metadata_id) {
    if (!this.metadata_instances.containsKey(metadata_id)) {
      System.err.println(
        "Metadata instance '${metadata_id}' was not found " +
          "amount metadata instances: ${this.metadata_instances.keySet()}"
      )
      System.exit(1)
    }

    return this.metadata_instances[metadata_id]
  }
}

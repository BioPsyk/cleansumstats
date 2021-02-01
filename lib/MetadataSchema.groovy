import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.JsonNodeType
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.networknt.schema.JsonSchema
import com.networknt.schema.JsonSchemaFactory
import com.networknt.schema.SpecVersion
import com.networknt.schema.ValidationMessage
import groovy.lang.MetaProperty
import java.nio.file.Path
import java.nio.file.Paths

/**
 * Represents a json-schema for the metadata file stored as YAML, instead of JSON.
 * Contains functionality to:
 *
 * - Parse schema files
 * - Validate metadata files
 * - Generation of metadata file templates
 */
class MetadataSchema {
  JsonSchema schema = null

  MetadataSchema(String schema_path) {
    def mapper = new ObjectMapper(new YAMLFactory());
    String schema_contents = new File(schema_path).getText('UTF-8')

    JsonSchemaFactory factory = JsonSchemaFactory.builder(
      JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V7)
    ).objectMapper(mapper).build();

    this.schema = factory.getSchema(schema_contents)
  }

  /**
   * Validates the given metadata after the loaded schema.
   *
   * @param metadata Metadata instance to validate.
   * @throws Exception When the validation fails.
   */
  public def read_metadata_file(Path metadata_path) {
    def mapper = new ObjectMapper(new YAMLFactory())

    mapper.findAndRegisterModules()

    def file = new File(metadata_path.toString())

    String metadata_contents = file.getText('UTF-8')
    JsonNode node = mapper.readTree(metadata_contents)

    Set<ValidationMessage> errors = this.schema.validate(node);

    if (errors) {
      String msg = ""

      (errors).each {
        msg += "- ${it}\n"
      }

      throw new Exception(msg)
    }

    Metadata result = mapper.readValue(metadata_contents, Metadata.class)
    result.source_path = metadata_path

    return result
  }

  /**
   * Shortcut for prefixing the given literal with a YAML comment #
   * at the start of each line.
   *
   * @param literal The literal to prefix.
   * @returns A list of lines with prefixed with a YAML comment.
   */
  private def prefix_with_yaml_comments(String literal) {
    return literal.tokenize("\n").collect {
      "# ${it}"
    }
  }

  /**
   * Shortcut for generating a section header based on the given ID.
   *
   * @param section_id The id to use to retrieve the header name.
   * @returns A list of lines that is the section header.
   */
  private def get_section_header(String section_id) {
    def section_name = ""

    switch (section_id) {
      case "cleansumstats":
        section_name = "Meta data section 0 - Pipeline information"
        break;
      case "path":
        section_name = "Meta data section 1 - File locations"
        break;
      case "study":
        section_name = "Meta data section 2 - Study descriptors"
        break;
      case "stats":
        section_name = "Meta data section 3 - Statistical descriptors"
        break;
      case "col":
        section_name = "Meta data section 4 - SumStats column descriptors"
        break;
      default:
        return []
    }

    def lines = []

    lines.addAll([
      "",
      "########################################################################",
      "# ${section_name}",
      "########################################################################",
    ])

    return lines
  }

  /**
   * Generates a complete metadata template using the description of the schema
   * and each fields description.
   *
   * @returns The generated metadata template.
   */
  public def generate_metadata_template() {
    JsonNode root_node = this.schema.getSchemaNode()
    Map required_lookup = [:]
    def root_description = root_node.get("description").asText()
    def lines = []

    lines.add("########################################################################")
    lines.add("#")
    lines.addAll(this.prefix_with_yaml_comments(root_description))
    lines.add("#")
    lines.add("########################################################################")

    root_node.get("required").elements().each {
      required_lookup[it] = true
    }

    def prev_section = ""

    root_node.get("properties").fields().each {
      def next_section = it.key.takeWhile { it != '_' }

      if (prev_section == "" || prev_section != next_section) {
        lines.addAll(this.get_section_header(next_section))
      }

      prev_section = next_section

      lines.addAll(["", "${it.key}:"])

      def description = it.value.get("description")

      if (description != null) {
        lines.addAll(this.prefix_with_yaml_comments(description.asText()))
      }

      lines.add("#")
      lines.add("# Field required: ${required_lookup.containsKey(it.key)}")
    }

    return lines.join("\n")
  }

  /**
   * Generates a complete groovy class that contains all metadata fields as class members.
   *
   * @returns The generated metadata class.
   */
  public def generate_metadata_groovy_class() {
    JsonNode root_node = this.schema.getSchemaNode()
    def root_description = root_node.get("description").asText()
    def lines = ["class Metadata {"]

    root_node.get("properties").fields().each {
      def data_type = it.value.get("type")
      def default_value = "null"
      data_type = data_type == null ? "string" : data_type.asText()

      switch (data_type) {
        case "uri":
        case "string":
          data_type = "String"
          break
        case "array":
          default_value = "[]"
          data_type = "List"
          break
        case "number":
          default_value = "0"
          data_type = "float"
          break
        case "integer":
          default_value = "0.0"
          data_type = "int"
          break
      }

      lines.add("  ${data_type} ${it.key} = ${default_value}")
    }

    lines.add("}")

    return lines.join("\n")
  }
}

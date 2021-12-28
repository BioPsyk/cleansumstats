
// -*- mode: groovy; -*-
// vim: syntax=groovy

nextflow.enable.dsl=2

include {
  extract_frequency_data
  flip_frequency_data
  sort_frequency_data
  join_frequency_data_on_dbsnp_reference
} from '../process/prepare_1kgaf.nf' 


workflow prepare_1kgaf_reference {

  take:
  input
  ch_dbsnp_38

  main:
  Channel
    .fromPath(params.input, type: 'file')
    .map { file -> tuple(file.baseName, file) }
    .set { ch_file }

  extract_frequency_data(ch_file)
  flip_frequency_data(extract_frequency_data.out)
  sort_frequency_data(flip_frequency_data.out)
  join_frequency_data_on_dbsnp_reference(sort_frequency_data.out, ch_dbsnp_38)

}



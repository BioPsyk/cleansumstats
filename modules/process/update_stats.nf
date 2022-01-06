process numeric_filter_stats {
  publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev
  publishDir "${params.outdir}/${datasetID}/intermediates/removed_lines", mode: 'rellink', overwrite: true, pattern: 'removed_*', enabled: params.dev

  input:
  tuple val(datasetID), path(sfile)
  //tuple datasetID, mfile, sfile from ch_stats_inference

  output:
  tuple val(datasetID), path("numeric_filter_stats__st_filtered_remains"), emit: ch_stats_filtered_remain00
  tuple val(datasetID), path("numeric_filter_stats__removed_stat_non_numeric_in_awk_ix"), emit: ch_stats_filtered_removed_ix
  tuple val(datasetID), path("numeric_filter_stats__desc_filtered_stat_rows_with_non_numbers_BA.txt"), emit: ch_desc_filtered_stat_rows_with_non_numbers_BA
  //file("numeric_filter_stats__removed_stat_non_numeric_in_awk")

  script:
  def metadata = params.sess.get_metadata(datasetID)
  Map stat_fields = metadata.resolve_stat_fields()
  int se_column_id = -1

  stat_fields.eachWithIndex { entry, i ->
    if (entry.key == "SE") {
      se_column_id = i
    }
  }

  """
  if [[ \$(wc -l $sfile | awk '{print \$1}') == "1" ]]
  then
    echo "[ERROR] The inputted file sfile did not have any data"
    exit 1
  fi

  touch numeric_filter_stats__removed_stat_non_numeric_in_awk
  touch numeric_filter_stats__removed_stat_non_numeric_in_awk_ix

  sstools-utils ad-hoc-do -f $sfile \
    -k "0|${stat_fields.values().join("|")}" \
    -n "0,${stat_fields.values().join(",")}" | \
    filter_stat_values_awk.sh -vzeroSE="${se_column_id}" \
      > numeric_filter_stats__st_filtered_remains 2> numeric_filter_stats__removed_stat_non_numeric_in_awk

  awk -vOFS="\t" '{print \$1,"stat_non_numeric_in_awk"}' numeric_filter_stats__removed_stat_non_numeric_in_awk > numeric_filter_stats__removed_stat_non_numeric_in_awk_ix

  if [[ \$(wc -l numeric_filter_stats__st_filtered_remains | awk '{print \$1}') == "1" ]]
  then
    echo "[ERROR] The outputted file st_filtered_remains did not have any data"
    exit 1
  fi

  #process before and after stats
  rowsBefore="\$(wc -l ${sfile} | awk '{print \$1}')"
  rowsAfter="\$(wc -l numeric_filter_stats__st_filtered_remains | awk '{print \$1}')"
  echo -e "\$rowsBefore\t\$rowsAfter\tFiltered out rows with stats impossible to do calculations from" > numeric_filter_stats__desc_filtered_stat_rows_with_non_numbers_BA.txt
  """
}

process convert_neglogP {

    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(sfile)
    //tuple val(datasetID), path(sfile) from ch_stats_filtered_remain00

    output:
    tuple val(datasetID), path("convert_neglogP"), emit: ch_convert_neglog10P
    //tuple datasetID, mfile, file("convert_neglogP") into ch_convert_neglog10P
    tuple val(datasetID), path("convert_neglogP_BA.txt"), emit: ch_desc_convert_neglog10P
    //tuple datasetID, file("convert_neglogP_BA.txt") into ch_desc_convert_neglog10P

    script:
    def metadata = params.sess.get_metadata(datasetID)
    """
    colneglog10P="${metadata.stats_neglog10P ?: "missing"}"
    colP="${metadata.col_P ?: "missing"}"

    if [ "\${colneglog10P}" == 'true' ]; then
      convert_neglogP.sh ${sfile} "\${colP}" > convert_neglogP
    else
      cp ${sfile} convert_neglogP
    fi

    #process before and after stats
    rowsBefore="\$(wc -l ${sfile} | awk '{print \$1}')"
    rowsAfter="\$(wc -l convert_neglogP | awk '{print \$1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tneglog10 Pvalue fix" > convert_neglogP_BA.txt
    """
}

process force_eaf {
    //publishDir "${params.outdir}/${mID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(mID), path(sfile)
    //tuple val(datasetID), path(sfile) from ch_convert_neglog10P

    output:
    tuple val(mID), path("force_eaf__st_forced_eaf"), emit: ch_stats_filtered_remain
    //tuple datasetID, file("force_eaf__st_forced_eaf") into ch_stats_filtered_remain
    tuple val(mID), path("force_eaf__desc_forced_eaf_BA.txt"), emit: ch_desc_forced_eaf_BA
    //tuple datasetID, file("force_eaf__desc_forced_eaf_BA.txt") into ch_desc_forced_eaf_BA

    script:
    def metadata = params.sess.get_metadata(mID)
    col_EAF="${metadata.col_EAF ?: "missing"}"
    col_OAF="${metadata.col_OAF ?: "missing"}"
    """
    if [[ \$(wc -l $sfile | awk '{print \$1}') == "1" ]]
    then
      echo "[ERROR] The inputted file sfile did not have any data"
      exit 1
    fi

    force_effect_allele_frequency.sh ${sfile} ${col_EAF} ${col_OAF}  > force_eaf__st_forced_eaf

    if [[ \$(wc -l st_forced_eaf | awk '{print \$1}') == "1" ]]
    then
      echo "[ERROR] The outputted file st_forced_eaf did not have any data"
      exit 1
    fi

    #process before and after stats
    rowsBefore="\$(wc -l ${sfile} | awk '{print \$1}')"
    rowsAfter="\$(wc -l force_eaf__st_forced_eaf | awk '{print \$1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tForced Effect Allele Frequency" > force_eaf__desc_forced_eaf_BA.txt
    """
}
process prep_af_stats {
    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(build), path(sfile)
    //tuple val(datasetID), val(build), path(sfile) from ch_allele_corrected_mix3

    output:
    tuple val(datasetID), env(avail), path("prep_af_stats__st_1kg_af_ref_sorted_joined_sorted_on_inx"), emit: ch_prep_ref_allele_frequency
    //tuple val(datasetID), env(avail), path("prep_af_stats__st_1kg_af_ref_sorted_joined_sorted_on_inx") into ch_prep_ref_allele_frequency
    //path("prep_af_stats__st_1kg_af_ref_sorted")
    //path("prep_af_stats__st_1kg_af_ref_sorted_joined")

    script:
    def metadata = params.sess.get_metadata(datasetID)
    study_Ancestry="${metadata.study_Ancestry ?: "missing"}"
    ch_kg1000AFGRCh38=params.kg1000AFGRCh38
    """
    avail="false"
    count=0
    # Important that this order is the same as in the allele frequency file
    for anc in EAS EUR AFR AMR SAS; do
      if [ "\${anc}" == "${study_Ancestry}" ]; then
        avail="true"
      fi
      count=\$((count+1))
    done

    # If we have an available ancestry reference frequency
    if [ \${avail} == "true" ]; then
      # Join with AF table using chrpos column (keep only rowindex and allele frequency, merge later)
      awk -vFS="\t" -vOFS="\t" '{print \$4"-"\$2"-"\$3, \$1}' ${sfile} | LC_ALL=C sort -k 1,1 -t "\$(printf '\t')" > prep_af_stats__st_1kg_af_ref_sorted
      awk -vFS=" " -vOFS="\t" -vcount=\${count} '{print \$1"-"\$2"-"\$3,\$count}' ${ch_kg1000AFGRCh38} | LC_ALL=C sort -k 1,1 -t "\$(printf '\t')"| LC_ALL=C join -1 1 -2 1 -t "\$(printf '\t')" -o 2.2 1.2 - prep_af_stats__st_1kg_af_ref_sorted > prep_af_stats__st_1kg_af_ref_sorted_joined
      echo -e "0\tAF_1KG_CS" > prep_af_stats__st_1kg_af_ref_sorted_joined_sorted_on_inx
      LC_ALL=C sort -k 1,1 prep_af_stats__st_1kg_af_ref_sorted_joined >> prep_af_stats__st_1kg_af_ref_sorted_joined_sorted_on_inx
    else
      touch prep_af_stats__st_1kg_af_ref_sorted
      touch prep_af_stats__st_1kg_af_ref_sorted_joined
      touch prep_af_stats__st_1kg_af_ref_sorted_joined_sorted_on_inx
    fi

    """
}



//if ancestry code (eg EUR)is available, add allele_frequency
process add_af_stats {

    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(st_filtered), val(availAF), path(afFreqs)
    //tuple val(datasetID), path(st_filtered), val(availAF), path(afFreqs) from ch_add_ref_freq

    output:
    tuple val(datasetID), val("g1kaf_stats_branch"), path("add_af_stats__st_added_1kg_ref"), emit: ch_added_ref_allele_frequency_kg
    //tuple datasetID, val("g1kaf_stats_branch"), file("add_af_stats__st_added_1kg_ref"), mfile into ch_added_ref_allele_frequency_kg
    tuple val(datasetID), val("default_stats_branch"), path("add_af_stats__st_added_1kg_ref"), emit: ch_added_ref_allele_frequency_default
    //tuple datasetID, val("default_stats_branch"), file("add_af_stats__st_added_1kg_ref"), mfile into ch_added_ref_allele_frequency_default

    script:
    """
    if [[ \$(wc -l $st_filtered | awk '{print \$1}') == "1" ]]
    then
      echo "[ERROR] The inputted file st_filtered did not have any data"
      exit 1
    fi

    # If we have an available ancestry reference frequency
    if [ "${availAF}" == "true" ]; then
      # Join with AF table using chrpos column add NA for missing fields
     LC_ALL=C join -e "NA" -t "\$(printf '\t')" -a 1 -1 1 -2 1 -o auto ${st_filtered} ${afFreqs} > add_af_stats__st_added_1kg_ref
    else
      head -n1 ${st_filtered} > add_af_stats__st_added_1kg_ref
    fi
    """
}


process infer_stats {

    publishDir "${params.outdir}/${datasetID}/intermediates/${af_branch}", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), val(af_branch), path(st_filtered)
    //tuple val(datasetID), af_branch, st_filtered, mfile from ch_stats_to_infer

    output:
    tuple val(datasetID), val(af_branch), path("infer_stats__st_inferred_stats"), emit: ch_stats_selection
    tuple val(datasetID), path("infer_stats__desc_inferred_stats_if_inferred_BA.txt"), emit: ch_desc_inferred_stats_if_inferred_BA
    //path("st_which_to_infer")
    //path("colfields")
    //path("colnames")
    //path("colpositions")

    script:
    def metadata = params.sess.get_metadata(datasetID)
    stats_Model="${metadata.stats_Model ?: "missing"}"
    col_B="${metadata.col_BETA ?: "missing"}"
    col_SE="${metadata.col_SE ?: "missing"}"
    col_Z="${metadata.col_Z ?: "missing"}"
    col_P="${metadata.col_P ?: "missing"}"
    col_OR="${metadata.col_OR ?: "missing"}"
    col_ORL95="${metadata.col_ORL95 ?: "missing"}"
    col_ORU95="${metadata.col_ORU95 ?: "missing"}"
    col_N="${metadata.col_N ?: "missing"}"
    col_CaseN="${metadata.col_CaseN ?: "missing"}"
    col_ControlN="${metadata.col_ControlN ?: "missing"}"
    col_EAF="${metadata.col_EAF ?: "missing"}"
    col_OAF="${metadata.col_OAF ?: "missing"}"
    """
    echo "${stats_Model}"

    if [[ \$(wc -l $st_filtered | awk '{print \$1}') == "1" ]]
    then
      echo "[ERROR] The inputted file st_filtered did not have any data"
      exit 1
    fi

    check_stat_inference_functionfile.sh "${af_branch}" \
      "${stats_Model}" \
      "${col_B}" \
      "${col_SE}" \
      "${col_Z}" \
      "${col_P}" \
      "${col_OR}" \
      "${col_ORL95}" \
      "${col_ORU95}" \
      "${col_N}" \
      "${col_CaseN}" \
      "${col_ControlN}" \
      "${col_EAF}" \
      "${col_OAF}" \
    > st_which_to_infer
    check_stat_inference_avail.sh colfields colnames colpositions $af_branch \
      "${col_B}" \
      "${col_SE}" \
      "${col_Z}" \
      "${col_P}" \
      "${col_OR}" \
      "${col_ORL95}" \
      "${col_ORU95}" \
      "${col_N}" \
      "${col_CaseN}" \
      "${col_ControlN}" \
      "${col_EAF}" \
      "${col_OAF}" \

    cf="\$(cat colfields)"
    cn="\$(cat colnames)"
    cp="\$(cat colpositions)"

    if [ -s st_which_to_infer ]; then

      if [ "${stats_Model}" == "linear" ]; then
        STATM2="lin"
      elif [ "${stats_Model}" == "logistic" ]; then
        STATM2="log"
      else
        echo "Requires a statmodel defined in metafile"
      fi

      thisdir="\$(pwd)"

      cat $st_filtered | sstools-utils ad-hoc-do -f - -k "\${cf}" -n"\${cn}" | r-stats-c-streamer --functionfile st_which_to_infer --skiplines 1 \${cp} --statmodel \${STATM2} --allelefreqswitch > infer_stats__st_inferred_stats

    else
      touch infer_stats__st_inferred_stats
    fi

    #process before and after stats
    rowsBefore="\$(wc -l ${st_filtered} | awk '{print \$1}')"
    rowsAfter="\$(wc -l infer_stats__st_inferred_stats | awk '{print \$1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tInferred stats, if stats are inferred" > infer_stats__desc_inferred_stats_if_inferred_BA.txt
    """
}

process merge_inferred_data {
  publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

  input:
  tuple val(datasetID), path("kgversion"), path("defaultversion")
  //tuple val(datasetID), path(kgversion), path(defaultversion) from ch_inferred_stats_combined

  output:
  tuple val(datasetID), path("merge_inferred_data__st_combined_set_of_inferred_data"), emit: ch_combined_set_of_inferred_data
  //file("merge_inferred_data__st_added_suffix")

  script:
  """
  # Add _1KG to all 1KG inferred variables
  add_suffix_to_colnames.sh "kgversion" "_1KG" > merge_inferred_data__st_added_suffix

  # Merge the data add NA for missing fields
  LC_ALL=C join -e "NA" -t "\$(printf '\t')" -a 1 -1 1 -2 1 -o auto "defaultversion" merge_inferred_data__st_added_suffix > merge_inferred_data__st_combined_set_of_inferred_data
  """
}

process select_stats_for_output {
    publishDir "${params.outdir}/${datasetID}/intermediates", mode: 'rellink', overwrite: true, enabled: params.dev

    input:
    tuple val(datasetID), path(inferred), val(stats_branch), path(sfile)
    //tuple datasetID, inferred, stats_branch, sfile from ch_stats_selection2

    output:
    tuple val(datasetID), path("select_stats__st_stats_for_output"), emit: ch_stats_for_output
    tuple val(datasetID), path("select_stats__selected_source.txt"), emit: ch_stats_for_output_selected_source
    tuple val(datasetID), path("select_stats__desc_from_inferred_to_joined_selection_BA.txt"), emit: ch_desc_from_inferred_to_joined_selection_BA
    tuple val(datasetID), path("select_stats__desc_from_sumstats_to_joined_selection_BA.txt"), emit: ch_desc_from_sumstats_to_joined_selection_BA

    script:
    def metadata = params.sess.get_metadata(datasetID)
    stats_Model="${metadata.stats_Model ?: "missing"}"
    col_B="${metadata.col_BETA ?: "missing"}"
    col_SE="${metadata.col_SE ?: "missing"}"
    col_Z="${metadata.col_Z ?: "missing"}"
    col_P="${metadata.col_P ?: "missing"}"
    col_OR="${metadata.col_OR ?: "missing"}"
    col_ORL95="${metadata.col_ORL95 ?: "missing"}"
    col_ORU95="${metadata.col_ORU95 ?: "missing"}"
    col_N="${metadata.col_N ?: "missing"}"
    col_CaseN="${metadata.col_CaseN ?: "missing"}"
    col_ControlN="${metadata.col_ControlN ?: "missing"}"
    col_EAF="${metadata.col_EAF ?: "missing"}"
    col_OAF="${metadata.col_OAF ?: "missing"}"
    col_INFO="${metadata.col_INFO ?: "missing"}"
    col_DIRECTION="${metadata.col_Direction ?: "missing"}"
    """
    select_stats_for_output.sh $sfile $inferred select_stats__selected_source.txt > select_stats__st_stats_for_output \
      "${stats_Model}" \
      "${col_B}" \
      "${col_SE}" \
      "${col_Z}" \
      "${col_P}" \
      "${col_OR}" \
      "${col_ORL95}" \
      "${col_ORU95}" \
      "${col_N}" \
      "${col_CaseN}" \
      "${col_ControlN}" \
      "${col_EAF}" \
      "${col_OAF}" \
      "${col_INFO}" \
      "${col_DIRECTION}"

    #process before and after stats
    rowsBefore="\$(wc -l ${inferred} | awk '{print \$1}')"
    rowsAfter="\$(wc -l select_stats__st_stats_for_output | awk '{print \$1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFrom inferred to joined selection of stats" > select_stats__desc_from_inferred_to_joined_selection_BA.txt

    #process before and after stats
    rowsBefore="\$(wc -l ${sfile} | awk '{print \$1}')"
    rowsAfter="\$(wc -l select_stats__st_stats_for_output | awk '{print \$1}')"
    echo -e "\$rowsBefore\t\$rowsAfter\tFrom raw sumstat to joined selection of stats" > select_stats__desc_from_sumstats_to_joined_selection_BA.txt
    """
}


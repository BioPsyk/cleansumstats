#!/usr/bin/env bash

#meta file
STATS=${1}
inferred=${2}
from_which_source=${3}
STATM=${4}
#These are previous variables but now set to internal defaults
B="B"
SE="SE"
Z="Z"
P="P"
OR="OR"
ORL95="ORL95"
ORU95="ORU95"
N="N"
CaseN="CaseN"
ControlN="ControlN"
EAF="EAF"
OAF="OAF"
CaseEAF="CaseEAF"
CaseOAF="CaseOAF"
ControlEAF="ControlEAF"
ControlOAF="ControlOAF"
INFO="INFO"
DIRECTION="DIRECTION"
StudyN="StudyN"

#recode as true or false
function recode_to_tf(){
  var=$1
  fl=${STATS}
  if head -n1 $fl | awk '{print $0" "}'1 | grep -q "[[:space:]]$var[[:space:]]"; then
    echo "true"
  else
    echo "false"
  fi
}

#recode as true or false
function specfunx_exists(){
  var=$1
  infs=$2
  head -n1 $infs | awk '{print $0" "}'1 | grep -q "[[:space:]]$var[[:space:]]"
}

#what is statmethod according to meta data file
#STATM="$(selRightHand "$(selColRow "^stats_Model:" $mefl)")"

#true or false (exists or not)
tfB="$(recode_to_tf $B)"
tfSE="$(recode_to_tf $SE)"
tfZ="$(recode_to_tf $Z)"
tfP="$(recode_to_tf $P)"
tfOR="$(recode_to_tf $OR)"
tfORL95="$(recode_to_tf $ORL95)"
tfORU95="$(recode_to_tf $ORU95)"
tfN="$(recode_to_tf $N)"
tfCaseN="$(recode_to_tf $CaseN)"
tfControlN="$(recode_to_tf $ControlN)"
tfEAF="$(recode_to_tf $EAF)"
tfOAF="$(recode_to_tf $OAF)"
tfCaseEAF="$(recode_to_tf $CaseEAF)"
tfCaseOAF="$(recode_to_tf $CaseOAF)"
tfControlEAF="$(recode_to_tf $ControlEAF)"
tfControlOAF="$(recode_to_tf $ControlOAF)"
tfINFO="$(recode_to_tf $INFO)"
tfDIRECTION="$(recode_to_tf $DIRECTION)"
tfStudyN="$(recode_to_tf $StudyN)"

if [ "$tfEAF" == true ] || [ "$tfOAF" == true ]; then
  EAF2="EAF"
  tfEAF2="true"
else
  EAF2="missing"
  tfEAF2="false"
fi

if [ "$tfCaseEAF" == true ] || [ "$tfCaseOAF" == true ]; then
  CaseEAF2="CaseEAF"
  tfCaseEAF2="true"
else
  CaseEAF2="missing"
  tfCaseEAF2="false"
fi

if [ "$tfControlEAF" == true ] || [ "$tfControlOAF" == true ]; then
  ControlEAF2="ControlEAF"
  tfControlEAF2="true"
else
  ControlEAF2="missing"
  tfControlEAF2="false"
fi


#which variables to filter
function which_to_select(){
  selected_source="${1}"
  if [ ${tfB} == "true" ]; then
    echo -e "${B}"
    echo "B" 1>&2
    echo -e "B\toriginal" >> ${selected_source}
  else
    if [ "${STATM}" == "linear" ]; then
      if specfunx_exists "beta_from_zscore_se" ${inferred}; then
        echo "beta_from_zscore_se"
        echo -e "B\tbeta_from_zscore_se" >> ${selected_source}
        echo "B" 1>&2
      elif specfunx_exists "beta_from_zscore_N_af" ${inferred}; then
        echo "beta_from_zscore_N_af"
        echo -e "B\tbeta_from_zscore_N_af" >> ${selected_source}
        echo "B" 1>&2
      elif specfunx_exists "beta_from_zscore_se_1KG" ${inferred}; then
        echo "beta_from_zscore_se_1KG"
        echo -e "B\tbeta_from_zscore_se_1KG" >> ${selected_source}
        echo "B" 1>&2
      elif specfunx_exists "beta_from_zscore_N_af_1KG" ${inferred}; then
        echo "beta_from_zscore_N_af_1KG"
        echo -e "B\tbeta_from_zscore_N_af_1KG" >> ${selected_source}
        echo "B" 1>&2
      else
        :
      fi
    elif [ "${STATM}" == "logistic" ]; then
      if specfunx_exists "beta_from_oddsratio" ${inferred}; then
        echo "beta_from_oddsratio"
        echo -e "B\tbeta_from_oddsratio" >> ${selected_source}
        echo "B" 1>&2
      elif specfunx_exists "beta_from_zscore_se" ${inferred}; then
        echo "beta_from_zscore_se"
        echo -e "B\tbeta_from_zscore_se" >> ${selected_source}
        echo "B" 1>&2
      else
        :
      fi
    fi
  fi
  if [ ${tfSE} == "true" ]; then
    echo -e "${SE}"
    echo "SE" 1>&2
    echo -e "SE\toriginal" >> ${selected_source}
  else
    if [ "${STATM}" == "linear" ]; then
      if specfunx_exists "se_from_zscore_beta" ${inferred}; then
        echo "se_from_zscore_beta"
        echo -e "SE\tse_from_zscore_beta" >> ${selected_source}
        echo "SE" 1>&2
      elif specfunx_exists "se_from_zscore_N_af" ${inferred}; then
        echo "se_from_zscore_N_af"
        echo -e "SE\tse_from_zscore_N_af" >> ${selected_source}
        echo "SE" 1>&2
      elif specfunx_exists "se_from_zscore_beta_1KG" ${inferred}; then
        echo "se_from_zscore_beta_1KG"
        echo -e "SE\tse_from_zscore_beta_1KG" >> ${selected_source}
        echo "SE" 1>&2
      elif specfunx_exists "se_from_zscore_N_af_1KG" ${inferred}; then
        echo "se_from_zscore_N_af_1KG"
        echo -e "SE\tse_from_zscore_N_af_1KG" >> ${selected_source}
        echo "SE" 1>&2
      else
        :
      fi
    elif [ "${STATM}" == "logistic" ]; then
      if specfunx_exists "se_from_beta_zscore" ${inferred}; then
        echo "se_from_beta_zscore"
        echo -e "SE\tse_from_beta_zscore" >> ${selected_source}
        echo "SE" 1>&2
      elif specfunx_exists "se_from_ORu95_ORl95" ${inferred}; then
        echo "se_from_ORu95_ORl95"
        echo -e "SE\tse_from_ORu95_ORl95" >> ${selected_source}
        echo "SE" 1>&2
      else
        :
      fi
    fi
  fi
  if [ ${tfZ} == "true" ]; then
    echo -e "${Z}"
    echo "Z" 1>&2
    echo -e "Z\toriginal" >> ${selected_source}
  else
    if [ "${STATM}" == "linear" ]; then
      if specfunx_exists "zscore_from_beta_se" ${inferred}; then
        echo "zscore_from_beta_se"
        echo -e "Z\tzscore_from_beta_se" >> ${selected_source}
        echo "Z" 1>&2
      elif specfunx_exists "zscore_from_pval_beta" ${inferred}; then
        echo "zscore_from_pval_beta"
        echo -e "Z\tzscore_from_pval_beta" >> ${selected_source}
        echo "Z" 1>&2
      elif specfunx_exists "zscore_from_pval_beta_N" ${inferred}; then
        echo "zscore_from_pval_beta_N"
        echo -e "Z\tzscore_from_pval_beta_N" >> ${selected_source}
        echo "Z" 1>&2
      elif specfunx_exists "zscore_from_beta_se_1KG" ${inferred}; then
        echo "zscore_from_beta_se_1KG"
        echo -e "Z\tzscore_from_beta_se_1KG" >> ${selected_source}
        echo "Z" 1>&2
      elif specfunx_exists "zscore_from_pval_beta_1KG" ${inferred}; then
        echo "zscore_from_pval_beta_1KG"
        echo -e "Z\tzscore_from_pval_beta_1KG" >> ${selected_source}
        echo "Z" 1>&2
      elif specfunx_exists "zscore_from_pval_beta_N_1KG" ${inferred}; then
        echo "zscore_from_pval_beta_N_1KG"
        echo -e "Z\tzscore_from_pval_beta_N_1KG" >> ${selected_source}
        echo "Z" 1>&2
      else
        :
      fi
    elif [ "${STATM}" == "logistic" ]; then
      if specfunx_exists "zscore_from_beta_se" ${inferred}; then
        echo "zscore_from_beta_se"
        echo -e "Z\tzscore_from_beta_se" >> ${selected_source}
        echo "Z" 1>&2
      elif specfunx_exists "zscore_from_pval_oddsratio" ${inferred}; then
        echo "zscore_from_pval_oddsratio"
        echo -e "Z\tzscore_from_pval_oddsratio" >> ${selected_source}
        echo "Z" 1>&2
      else
        :
      fi
    fi
  fi
  if [ ${tfP} == "true" ]; then
    echo -e "${P}"
    echo "P" 1>&2
    echo -e "P\toriginal" >> ${selected_source}
  else
    if [ "${STATM}" == "linear" ]; then
      if specfunx_exists "pval_from_zscore_N" ${inferred}; then
        echo "pval_from_zscore_N"
        echo -e "P\tpval_from_zscore_N" >> ${selected_source}
        echo "P" 1>&2
      elif specfunx_exists "pval_from_zscore" ${inferred}; then
        echo "pval_from_zscore"
        echo -e "P\tpval_from_zscore" >> ${selected_source}
        echo "P" 1>&2
      elif specfunx_exists "pval_from_zscore_N_1KG" ${inferred}; then
        echo "pval_from_zscore_N_1KG"
        echo -e "P\tpval_from_zscore_N_1KG" >> ${selected_source}
        echo "P" 1>&2
      elif specfunx_exists "pval_from_zscore_1KG" ${inferred}; then
        echo "pval_from_zscore_1KG"
        echo -e "P\tpval_from_zscore_1KG" >> ${selected_source}
        echo "P" 1>&2
      else
        :
      fi
    elif [ "${STATM}" == "logistic" ]; then
      if specfunx_exists "pval_from_zscore" ${inferred}; then
        echo "pval_from_zscore"
        echo -e "P\tpval_from_zscore" >> ${selected_source}
        echo "P" 1>&2
      else
        :
      fi
    fi
  fi
  if [ ${tfOR} == "true" ]; then
    echo -e "${OR}"
    echo "OR" 1>&2
    echo -e "OR\toriginal" >> ${selected_source}
  fi
  if [ ${tfORL95} == "true" ]; then
    echo -e "${ORL95}"
    echo "ORL95" 1>&2
    echo -e "ORL95\toriginal" >> ${selected_source}
  fi

  if [ ${tfORU95} == "true" ]; then
    echo -e "${ORU95}"
    echo "ORU95" 1>&2
    echo -e "ORU95\toriginal" >> ${selected_source}
  fi
  if [ ${tfN} == "true" ]; then
    echo -e "${N}"
    echo "N" 1>&2
    echo -e "N\toriginal" >> ${selected_source}
  else
    if [ "${STATM}" == "linear" ]; then
      if specfunx_exists "N_from_zscore_beta_af" ${inferred}; then
        echo "N_from_zscore_beta_af"
        echo -e "N\tN_from_zscore_beta_af" >> ${selected_source}
        echo "N" 1>&2
      elif specfunx_exists "N_from_zscore_beta_af_1KG" ${inferred}; then
        echo "N_from_zscore_beta_af_1KG"
        echo -e "N\tN_from_zscore_beta_af_1KG" >> ${selected_source}
        echo "N" 1>&2
      else
        :
      fi
    elif [ "${STATM}" == "logistic" ]; then
      if specfunx_exists "Neff_from_Nca_Nco" ${inferred}; then
        echo "Neff_from_Nca_Nco"
        echo -e "Neff\tNeff_from_Nca_Nco" >> ${selected_source}
        echo "Neff" 1>&2
      else
        :
      fi
    fi
  fi
  if [ ${tfCaseN} == "true" ]; then
    echo -e "${CaseN}"
    echo "CaseN" 1>&2
    echo -e "CaseN\toriginal" >> ${selected_source}
  fi
  if [ ${tfControlN} == "true" ]; then
    echo -e "${ControlN}"
    echo "ControlN" 1>&2
    echo -e "ControlN\toriginal" >> ${selected_source}
  fi
  if [ ${tfEAF2} == "true" ]; then
    echo -e "${EAF2}"
    echo "EAF" 1>&2
    echo -e "EAF\toriginal" >> ${selected_source}
  else
    if [ "${STATM}" == "linear" ]; then
      :
    elif [ "${STATM}" == "logistic" ]; then
      if specfunx_exists "AF_from_CaseAF_ControlAF" ${inferred}; then
        echo "AF_from_CaseAF_ControlAF"
        echo -e "EAF\tAF_from_CaseAF_ControlAF" >> ${selected_source}
        echo "EAF" 1>&2
      else
        :
      fi
    fi
  fi
  if [ ${tfCaseEAF2} == "true" ]; then
    echo -e "${CaseEAF2}"
    echo "CaseEAF" 1>&2
    echo -e "CaseEAF\toriginal" >> ${selected_source}
  fi
  if [ ${tfControlEAF2} == "true" ]; then
    echo -e "${ControlEAF2}"
    echo "ControlEAF" 1>&2
    echo -e "ControlEAF\toriginal" >> ${selected_source}
  fi
  if specfunx_exists "AF_1KG_CS" ${STATS}; then
    echo -e "AF_1KG_CS"
    echo "EAF_1KG" 1>&2
    echo -e "EAF_1KG\tAF_1KG_CS" >> ${selected_source}
  fi
  if [ ${tfINFO} == "true" ]; then
    echo -e "${INFO}"
    echo -e "INFO\toriginal" >> ${selected_source}
    echo "INFO" 1>&2
  fi
  if [ ${tfDIRECTION} == "true" ]; then
    echo -e "${DIRECTION}"
    echo -e "Direction\toriginal" >> ${selected_source}
    echo "Direction" 1>&2
  fi
  if [ ${tfStudyN} == "true" ]; then
    echo -e "${StudyN}"
    echo -e "StudyN\toriginal" >> ${selected_source}
    echo "StudyN" 1>&2
  fi
}

var=$(which_to_select "${from_which_source}" 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam=$(which_to_select "/dev/null" 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')

#cat $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}"
if [ -s $inferred ]; then
  LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 $inferred $STATS | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}"
else
  cat $STATS | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}"
fi

#cat $inferred | sstools-utils ad-hoc-do -f - -k "0|${Z_fr_B_SE}" -n"0,${Z}"

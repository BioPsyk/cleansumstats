#!/usr/bin/env bash

#meta file
STATS=${1}
af_branch=${2}
STATM=${3}

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

function recode_to_tf(){
  var=$1
  fl=${STATS}
  if head -n1 $fl | awk '{print $0" "}'1 | grep -q "[[:space:]]$var[[:space:]]"; then
    echo "true"
  else
    echo "false"
  fi
}

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

#Check if either EAF or OAF is specified in meta, if so, use the new variable with fixed name: EAF
if [ "$af_branch" == "g1kaf_stats_branch" ]; then
    EAF2="AF_1KG_CS"
    tfEAF2="true"
else
  if [ "$tfEAF" == true ] || [ "$tfOAF" == true ]; then
    EAF2="EAF"
    tfEAF2="true"
  else
    EAF2="missing"
    tfEAF2="false"
  fi

fi

if [ "$tfCaseEAF" == true ] || [ "$tCasefOAF" == true ]; then
  CaseEAF2="CaseEAF"
  tfCaseEAF2="true"
else
  CaseEAF2="missing"
  tfCaseEAF2="false"
fi

if [ "$tfControlEAF" == true ] || [ "$tControlfOAF" == true ]; then
  ControlEAF2="ControlEAF"
  tfControlEAF2="true"
else
  ControlEAF2="missing"
  tfControlEAF2="false"
fi

#which variables to infer (linear)
if [ ${STATM} == "linear" ]; then
  if [ ${tfB} == "true" ] && [ ${tfSE} == "true" ]; then
    echo -e "zscore_from_beta_se"
  fi
  if [ ${tfB} == "true" ] && [ ${tfP} == "true" ]; then
    echo -e "zscore_from_pval_beta"
  fi
  if [ ${tfB} == "true" ] && [ ${tfP} == "true" ] && [ ${tfN} == "true" ]; then
    echo -e "zscore_from_pval_beta_N"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfN} == "true" ]; then
    echo -e "pval_from_zscore_N"
  fi
  if [ ${tfZ} == "true" ]; then
    echo -e "pval_from_zscore"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfSE} == "true" ]; then
    echo -e "beta_from_zscore_se"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfN} == "true" ] && [ ${tfEAF2} == "true" ]; then
    echo -e "beta_from_zscore_N_af"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfB} == "true" ]; then
    echo -e "se_from_zscore_beta"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfN} == "true" ] && [ ${tfEAF2} == "true" ]; then
    echo -e "se_from_zscore_N_af"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfB} == "true" ] && [ ${tfEAF2} == "true" ]; then
    echo -e "N_from_zscore_beta_af"
  fi
fi

#which variables to infer (logistic)
if [ ${STATM} == "logistic" ]; then
  if [ ${tfB} == "true" ] && [ ${tfSE} == "true" ]; then
    echo -e "zscore_from_beta_se"
  fi
  if [ ${tfOR} == "true" ] && [ ${tfP} == "true" ]; then
    echo -e "zscore_from_pval_oddsratio"
  fi
  if [ ${tfZ} == "true" ]; then
    echo -e "pval_from_zscore"
  fi
  if [ ${tfOR} == "true" ]; then
    echo -e "beta_from_oddsratio"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfSE} == "true" ]; then
    echo -e "beta_from_zscore_se"
  fi
  if [ ${tfB} == "true" ] && [ ${tfZ} == "true" ]; then
    echo -e "se_from_beta_zscore"
  fi
  if [ ${tfORL95} == "true" ] && [ ${tfORU95} == "true" ]; then
    echo -e "se_from_ORu95_ORl95"
  fi
  if [ ${tfControlN} == "true" ] && [ ${tfCaseN} == "true" ]; then
    echo -e "Neff_from_Nca_Nco"
  fi
  if [ ${tfControlN} == "true" ] && [ ${tfCaseN} == "true" ] && [ ${tfCaseEAF2} == "true" ] && [ ${tfControlEAF2} == "true" ]; then
    echo -e "AF_from_CaseAF_ControlAF"
  fi
fi


#!/usr/bin/env bash

#meta file
af_branch=${1}
STATM=${2}
B=${3}
SE=${4}
Z=${5}
P=${6}
OR=${7}
ORL95=${8}
ORU95=${9}
N=${10}
CaseN=${11}
ControlN=${12}
EAF=${13}
OAF=${14}

#recode as true or false
function recode_to_tf(){
  if [ "$1" == "missing" ]; then
    echo false
  else
    echo true
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
fi


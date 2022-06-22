#!/usr/bin/env bash

colf=$1
coln=$2
argn=$3
af_branch=$4
STATS=$5

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

#which args to use
cat <<EOF > argsfile.txt
$B
$SE
$Z
$P
$OR
$ORL95
$ORU95
$N
$CaseN
$ControlN
$EAF2
EOF

cat <<EOF > argsfileTF.txt
$tfB
$tfSE
$tfZ
$tfP
$tfOR
$tfORL95
$tfORU95
$tfN
$tfCaseN
$tfControlN
$tfEAF2
EOF

cat <<EOF > argsfile2.txt
beta
standarderror
zscore
pvalue
oddsratio
ORu95
ORl95
Nindividuals
Ncases
Ncontrols
allelefreq
EOF

nrows=$( cat argsfile2.txt | wc -l )

printf "%s" "0" > ${coln}
printf "%s" "0" > ${colf}
printf "%s" "--index 1" > ${argn}

c=2
for i in $(seq 1 ${nrows}); do
  el1="$(awk -vc="${i}" 'NR==c{print $0}' argsfile.txt)"
  el2="$(awk -vc="${i}" 'NR==c{print $0}' argsfileTF.txt)"
  el3="$(awk -vc="${i}" 'NR==c{print $0}' argsfile2.txt)"
  if [ "${el2}" == "true" ];then
    printf ",%s" "${el1}" >> ${coln}
    printf "|%s" "${el1}" >> ${colf}
    printf " %s" "--${el3} $c" >> ${argn}
    c=$((c+1))
  else
    :
  fi
done

#set newline
printf "\n" >> ${coln}
printf "\n" >> ${colf}
printf "\n" >> ${argn}

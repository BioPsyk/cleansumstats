mefl=$1
sfile=$2

#helpers
function selRightHand(){
  echo "${1#*: }"
}
function selColRow(){
  grep ${1} ${2}
}

#recode as true or false
function recode_to_tf(){
  if [ $1 == "missing" ]; then
  echo false
  else
  echo true
  fi
}



#check if EAF or OAF is specified in metadatafile
EAF="$(selRightHand "$(selColRow "^col_EAF:" $mefl)")"
OAF="$(selRightHand "$(selColRow "^col_OAF:" $mefl)")"
tfEAF="$(recode_to_tf $EAF)"
tfOAF="$(recode_to_tf $OAF)"

#make new var EAF if possible
if [ ${tfEAF} == "true" ]; then
  # Just change colname
  awk -vFS="\t" -vOFS="\t" -vtochange="${EAF}" '
  NR==1{for(k=1; k <= NF-1; k++){if($k==tochange){printf "%s%s", "EAF", OFS}else{printf "%s%s", $(k), OFS }}; if($NF==tochange){print "EAF"}else{print $NF}}; NR>1{print $0}' $sfile
elif [ ${tfOAF} == "true" ]; then
  # Mod and change colname
  head -n1  $sfile | awk -vFS="\t" -vOFS="\t" -vtochange="${EAF}" '
  NR==1{for(k=1; k <= NF-1; k++){if($k==tochange){printf "%s%s", "EAF", OFS}else{printf "%s%s", $(k), OFS }}; if($NF==tochange){print "EAF"}else{print $NF}}'
  whichToChange="$(head -n1  $sfile | awk -vFS="\t" -vOFS="\t" -vtochange="${OAF}" '{for(k=1; k <= NF; k++){if($k==tochange){print k}}}' )"
  awk -vFS="\t" -vOFS="\t" -vtochange="${whichToChange}" '
  NR>1{for(k=1; k <= NF-1; k++){if(k==tochange){eaf=1-$k; printf "%s%s", eaf, OFS}else{printf "%s%s", $k, OFS }}; if(NF==tochange){eaf=1-$NF; print eaf}else{print $NF }}' $sfile
else
  cat $sfile
fi

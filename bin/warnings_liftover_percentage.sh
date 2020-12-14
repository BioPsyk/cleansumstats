#meta file
grmax=${1}
tot=${2}
buildstat=${3}
dID2=${4}

#caluclate mapping percentage
perc="$(echo "${grmax}" | awk -vtot="${tot}" '{print $1/tot}')"
percOther1="$(awk -vtot="${tot}" 'NR==1{print $1/tot }' ${buildstat})"
gbOther1="$(awk 'NR==1{print $2}' ${buildstat})"
percOther2="$(awk -vtot="${tot}" 'NR==2{print $1/tot }' ${buildstat})"
gbOther2="$(awk 'NR==2{print $2}' ${buildstat})"
percOther3="$(awk -vtot="${tot}" 'NR==3{print $1/tot }' ${buildstat})"
gbOther3="$(awk 'NR==3{print $2}' ${buildstat})"

#check that GRChmax has at least 90% hits in dbsnp
if (( $(echo "${perc} 0.90" | awk '{print ($1 < $2)}') )); then
  echo -e "only few hits (${perc}%) for the best matching build, ${dID2}"
else
  :
fi

#check that the others have less than 60% hits in dbsnp
if (( $(echo "${percOther1} 0.60" | awk '{print ($1 < $2)}') )); then
  echo -e "too many hits of a not selected build ${gbOther1} (${percOther1}%), ${dID2}"
else
  :
fi
#check that the others have less than 60% hits in dbsnp
if (( $(echo "${percOther2} 0.60" | awk '{print ($1 < $2)}') )); then
  echo -e "too many hits of a not selected build ${gbOther2} (${percOther2}%), ${dID2}"
else
  :
fi
#check that the others have less than 60% hits in dbsnp
if (( $(echo "${percOther3} 0.60" | awk '{print ($1 < $2)}') )); then
  echo -e "too many hits of a not selected build ${gbOther3} (${percOther3}%), ${dID2}"
else
  :
fi





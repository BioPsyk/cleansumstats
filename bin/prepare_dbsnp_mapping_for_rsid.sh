sfile=${1}
snpExists=${2}
out1=${3}
out2=${4}
colSNP=${5}

echo -e "Markername\t0" > ${out1}
echo -e "0\tMarkername" > ${out2}

if [ "${snpExists}" == "true" ]
then
  # Select columns and then split in one rs file and one snpchrpos file
  cat ${sfile} | sstools-utils ad-hoc-do -k "0|${colSNP}" -n"0,Markername" | awk -vFS="\t" -vOFS="\t" '{print $2,$1}' | awk -vFS="\t" -vOFS="\t" -vout2=${out2} 'NR>1{if($1 ~ /^rs.*/){ print $0 }else{ print $2,$1 >> out2 }}' >> ${out1}
  # Rearrange markername_chrpos output

elif [ "${snpExists}" == "false" ]
then
  # Use the empty header data to continue with, which should make this branch quick
  :
else
  >&2 echo "snpExists, must be true or false, not: $snpExists"
  exit 1
fi



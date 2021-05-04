sfile=${1}
snpExists=${2}
colSNP=${3}
out1=${4}
out2=${5}

echo -e "RSID\t0" > ${out1}
echo -e "Markername\t0" > ${out2}

if [ "${snpExists}" == "true" ]
then
  # Select columns and then split in one rs file and one snpchrpos file
  cat ${sfile} | sstools-utils ad-hoc-do -k "0|${colSNP}" -n"0,RSID" | awk -vFS="\t" -vOFS="\t" '{print $2,$1}' | awk -vFS="\t" -vOFS="\t" -vout2=${out2} 'NR>1{if($1 ~ /^rs.*/){ print $0 }else{ print $0 >> out2 }}' >> ${out1}
fi

#else, Use the empty header data to continue with, which should make this branch quick


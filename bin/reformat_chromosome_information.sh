sfile=${1}
colCHR=${2}
outfile=${3}

# Check number of rows in file
nrrows="$(wc -l ${sfile})"

# If only header row, then do nothing
if [ "${nrrows}" == "1" ]
then
  # Will just forward the header, as the header should be the only thing present if this is true
  cat ${sfile}  > ${outfile}
else
  cat $sfile | sstools-utils ad-hoc-do -k "0|funx_force_sex_chromosomes_format(${colCHR})" -n"0,${colCHR}" > new_chr_sex_format

 # echo "--------------------------"
 # echo "new_chr_sex_format"
 # cat new_chr_sex_format

  # Remove sex formats of unknown origin
  echo "${colCHR}" > gb_ad-hoc-do_funx_CHR_sex_chrom_filter
  cat new_chr_sex_format | sstools-utils ad-hoc-do -k "0|${colCHR}" -n"0,CHR" | awk -vFS="\t" -vOFS="\t" 'BEGIN{getline; print $0}; {if($2 > 0 && $2 < 27){ print $1, $2 }}' > new_chr_sex_format2

 # echo "--------------------------"
 # echo "new_chr_sex_format2"
 # cat new_chr_sex_format2

  #use the index to remove everything no part of chr numers 1-26 but keep original format
  LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 -1 1 -2 1 new_chr_sex_format new_chr_sex_format2 > new_chr_sex_format3

  # Replace (if bp or allele info is in the same column it will be kept, as the function above only replaces the chr info part)
  head -n1 $sfile > header
  to_keep_from_join="$(awk -vFS="\t" -vobj=${colCHR} '{for (i=1; i<=NF; i++){if(obj==$i){print "2."2}else{print "1."i}}}' header)"
 # echo "--------------------------"
 # echo "new_chr_sex_format3"
 # cat new_chr_sex_format3
 # echo "--------------------------"
 # cat ${sfile}
  LC_ALL=C join -t "$(printf '\t')" -o ${to_keep_from_join} -1 1 -2 1 $sfile new_chr_sex_format3 > ${outfile}
fi


dir1=$1
dir2=$2

dirx="$(basename ${dir1})"
fn="${dirx}.gz"
file="*.gz"
OUT_log="${dir2}/${dirx}_formatting.log"
dat="$(date)"

echo "" >> ${OUT_log} 2>&1
echo "init $dat" > ${OUT_log} 2>&1

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "gziptest" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
gzip -vt ${dir1}/${file} > /dev/null 2>&1

#if previous command was successful
if [ $? == 0  ]; then
 gziptest_result="ok" 
 echo "gzip-check1 ok" >> ${OUT_log}
else
 gziptest_result="fail" 
 echo "gzip-check1 fail" >> ${OUT_log}
fi

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "force space separators as tab-sep" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
zcat ${dir1}/${file} | awk -vFS="[[:space:]]" -vOFS="\t" 'NR<1000{for(k=1; k <= NF-1; k++){printf "%s%s", $(k), OFS }; print $(NF)}' | gzip -c > ${dir2}/tabtmp.gz 2> /dev/null

#if previous command was successful
if [ $? == 0  ]; then
 tab_sep_result1="ok" 
 echo "tab-sep-enforce1 ok" >> ${OUT_log}
else
 tab_sep_result1="fail" 
 echo "tab-sep-enforce1 fail" >> ${OUT_log}
fi

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "Check if the header is treated like only one field" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
one_field_header_result1=$(zcat ${dir2}/tabtmp.gz | awk -vFS="\t" 'NR==1{
  if (rows==0){ print "ok"}
  if (rows!=0){ print "fail"}
}') 2> /dev/null

#if previous command was successful
if [ $? == 0  ]; then
 one_field_header_result2="ok" 
 echo "header-check1 ${one_field_header_result1}" >> ${OUT_log}
 echo "header-check2 ok" >> ${OUT_log}
else
 one_field_header_result2="fail" 
 echo "header-check1 ${one_field_header_result1}" >> ${OUT_log}
 echo "header-check2 fail" >> ${OUT_log}
fi


echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "tab-sep-NF-same" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
tab_sep_NF_result1=$(zcat ${dir2}/tabtmp.gz | awk -vFS="\t" '
NR==1 {comp=NF}
NF!=comp {rows=+1}
END {
  if (rows==0){ print "ok"}
  if (rows!=0){ print "fail"}
}') 2> /dev/null

#if previous command was successful
if [ $? == 0  ]; then
 tab_sep_NF_result2="ok" 
 echo "tab-sep1 ${tab_sep_NF_result1}" >> ${OUT_log}
 echo "tab-sep2 ok" >> ${OUT_log}
else
 tab_sep_NF_result2="fail" 
 echo "tab-sep1 ${tab_sep_NF_result1}" >> ${OUT_log}
 echo "tab-sep2 fail" >> ${OUT_log}
fi

#remove tmp file
rm ${dir2}/tabtmp.gz

if [ $gziptest_result == "ok" ] && [ $tab_sep_result1 == "ok" ] && [ $one_field_header_result1 == "ok" ] && [ $one_field_header_result2 == "ok" ] && [ $tab_sep_NF_result1 == "ok" ] && [ $tab_sep_NF_result2 == "ok" ] ; then
  first_test_set="ok"
else
  first_test_set="fail"
fi

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1

if [ $first_test_set == "ok" ]; then

  echo "##############################" >> ${OUT_log} 2>&1
  echo "All basic checks ok for first 1000 lines, now format and test whole" >> ${OUT_log} 2>&1
  echo "##############################" >> ${OUT_log} 2>&1
  
  echo "##############################" >> ${OUT_log} 2>&1
  echo "force space separators as tab-sep" >> ${OUT_log} 2>&1
  echo "##############################" >> ${OUT_log} 2>&1
  zcat ${dir1}/${file} | awk -vFS="[[:space:]]" -vOFS="\t" '{for(k=1; k <= NF-1; k++){printf "%s%s", $(k), OFS }; print $(NF)}' | gzip -c > ${dir2}/${fn} 2> /dev/null
  
  #if previous command was successful
  if [ $? == 0  ]; then
   tab_sep_result2="ok" 
   echo "tab-sep-enforce2 ok" >> ${OUT_log}
  else
   tab_sep_result2="fail" 
   echo "tab-sep-enforce2 fail" >> ${OUT_log}
  fi

  echo "" >> ${OUT_log} 2>&1
  echo "" >> ${OUT_log} 2>&1
  echo "##############################" >> ${OUT_log} 2>&1
  echo "Check if the header is treated like only one field" >> ${OUT_log} 2>&1
  echo "##############################" >> ${OUT_log} 2>&1
  one_field_header_result3=$(zcat ${dir2}/${fn} | awk -vFS="\t" 'NR==1{
    if (rows==0){ print "ok"}
    if (rows!=0){ print "fail"}
  }') 2> /dev/null
  
  #if previous command was successful
  if [ $? == 0  ]; then
   one_field_header_result4="ok" 
   echo "header-check1 ${one_field_header_result1}" >> ${OUT_log}
   echo "header-check2 ok" >> ${OUT_log}
  else
   one_field_header_result4="fail" 
   echo "header-check1 ${one_field_header_result1}" >> ${OUT_log}
   echo "header-check2 fail" >> ${OUT_log}
  fi

  echo "" >> ${OUT_log} 2>&1
  echo "" >> ${OUT_log} 2>&1
  echo "##############################" >> ${OUT_log} 2>&1
  echo "tab-sep-NF-same" >> ${OUT_log} 2>&1
  echo "##############################" >> ${OUT_log} 2>&1
  tab_sep_NF_result3=$(zcat ${dir2}/${fn} | awk -vFS="\t" '
  NR==1 {comp=NF}
  NF!=comp {rows=+1}
  END {
    if (rows==0){ print "ok"}
    if (rows!=0){ print "fail"}
  }') 2> /dev/null

  #find missmatch line using this command
  #awk -vFS="\t" '
  #NR==1 {comp=NF}
  #NF!=comp {print NR,NF,comp, $0}
  #'

  #if previous command was successful
  if [ $? == 0  ]; then
   tab_sep_NF_result4="ok" 
   echo "tab-sep1 ${tab_sep_NF_result3}" >> ${OUT_log}
   echo "tab-sep2 ok" >> ${OUT_log}
  else
   tab_sep_NF_result4="fail" 
   echo "tab-sep1 ${tab_sep_NF_result3}" >> ${OUT_log}
   echo "tab-sep2 fail" >> ${OUT_log}
  fi
  
  if [ $tab_sep_result2 == "ok" ] && [ $one_field_header_result3 == "ok" ] && [ $one_field_header_result4 == "ok" ] && [ $tab_sep_NF_result3 == "ok" ] && [ $tab_sep_NF_result4 == "ok" ] ; then
    second_test_set="ok"
  else
    second_test_set="fail"
  fi
  
  echo "" >> ${OUT_log} 2>&1
  echo "" >> ${OUT_log} 2>&1
  
  if [ $second_test_set == "ok" ]; then
  
  echo "##############################" >> ${OUT_log} 2>&1
  echo "All basic checks ok now for the whole file" >> ${OUT_log} 2>&1
  echo "##############################" >> ${OUT_log} 2>&1
  
  else
    echo "something failed during basic checks nr2, when testing the whole file" >> ${OUT_log}
   echo "tab_sep_result2 ${tab_sep_result2}" >> ${OUT_log}
   echo "one_field_header_result3 ${one_field_header_result3}" >> ${OUT_log}
   echo "one_field_header_result4 ${one_field_header_result4}" >> ${OUT_log}
   echo "tab_sep_NF_result3 ${tab_sep_NF_result3}" >> ${OUT_log}
   echo "tab_sep_NF_result4 ${tab_sep_NF_result4}" >> ${OUT_log}
  fi

else
  echo "something failed during basic checks, not proceeding to testing the whole file" >> ${OUT_log}
   echo "gziptest_result ${gziptest_result}" >> ${OUT_log}
   echo "tab_sep_result1 ${tab_sep_result1}" >> ${OUT_log}
   echo "one_field_header_result1 ${one_field_header_result1}" >> ${OUT_log}
   echo "one_field_header_result2 ${one_field_header_result2}" >> ${OUT_log}
   echo "tab_sep_NF_result1 ${tab_sep_NF_result1}" >> ${OUT_log}
   echo "tab_sep_NF_result2 ${tab_sep_NF_result2}" >> ${OUT_log}
fi

if [ $second_test_set == "ok" ]
then
  echo >&2 "all seems ok with the summary statistics file"
  exit 0
else
  echo >&2 "one or more problems detected with the meta data format, see logfile"
  exit 1
fi

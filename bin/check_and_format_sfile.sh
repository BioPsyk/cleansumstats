fn=$1
outfile=$2
OUT_log=$3
dat="$(date)"

echo "init $dat" > ${OUT_log} 2>&1

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "gziptest" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
gzip -vt ${fn} > /dev/null 2>&1

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
zcat ${fn} | awk -vFS="[[:space:]]" -vOFS="\t" '{for(k=1; k <= NF-1; k++){printf "%s%s", $(k), OFS }; print $(NF)}' > ${outfile} 2> /dev/null

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
one_field_header_result1=$(cat ${outfile} | awk -vFS="\t" 'NR==1{
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
tab_sep_NF_result1=$(cat ${outfile} | awk -vFS="\t" '
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

if [ $gziptest_result == "ok" ] && [ $tab_sep_result1 == "ok" ] && [ $one_field_header_result1 == "ok" ] && [ $one_field_header_result2 == "ok" ] && [ $tab_sep_NF_result1 == "ok" ] && [ $tab_sep_NF_result2 == "ok" ] ; then
  first_test_set="ok"
else
  first_test_set="fail"
fi

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1

if [ $first_test_set == "ok" ]; then
  echo "" >> ${OUT_log}
  echo "all seems ok with the summary statistics file" >> ${OUT_log}
  exit 0
else
  echo "something failed during basic checks, not proceeding to testing the whole file" >> ${OUT_log}
  echo "gziptest_result ${gziptest_result}" >> ${OUT_log}
  echo "tab_sep_result1 ${tab_sep_result1}" >> ${OUT_log}
  echo "one_field_header_result1 ${one_field_header_result1}" >> ${OUT_log}
  echo "one_field_header_result2 ${one_field_header_result2}" >> ${OUT_log}
  echo "tab_sep_NF_result1 ${tab_sep_NF_result1}" >> ${OUT_log}
  echo "tab_sep_NF_result2 ${tab_sep_NF_result2}" >> ${OUT_log}
  echo "" >> ${OUT_log}
  echo >&2 "one or more problems detected with the meta data format, see logfile" 
  exit 1
fi

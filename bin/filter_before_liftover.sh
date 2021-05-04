liftedandmapped=$1
filtering=$2
out1=$3
out2=$4
out3=$5

#split comma separated list into bash array
filterArr=($(echo "${filtering}" | awk '{gsub(/ /, "", $0); print}' | awk '{gsub(/,/, "\n", $0); print}' ))

touch ${out1}
touch ${out2}
touch ${out3}

cp ${liftedandmapped} gb_unique_rows

##check if no filtering will be applied
#if [ "${#filterArr[@]}" -eq 0 ]
#then
#  applyFilter="no"
#else
#  applyFilter="yes"
#fi

LC_ALL=C sort -k1,1 gb_unique_rows > gb_unique_rows_sorted

#loop over bash array applying each correspondinng filtering type in the samee order
for var in ${filterArr[@]}; do

  #the data will be having either chrpos or rsids as first column
  if [ "${var}" == "duplicated_keys" ]
  then
    touch removed_duplicated_rows_keys
    awk 'BEGIN{r0="initrowhere"} {var=$1; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_keys"}; r0=var}' gb_unique_rows_sorted > gb_unique_rows2
    awk -vOFS="\t" '{print $2, "removed_duplicated_rows_dbsnpkeys"}' removed_duplicated_rows_keys >> removed_duplicated_rows
    rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to chr:pos or rsids" >> desc_removed_duplicated_rows
    mv gb_unique_rows2 gb_unique_rows
    echo "duplicated_dbsnpkey" >> beforeLiftoverFiltering_executionorder
  fi
done

mv gb_unique_rows ${out1}
mv removed_duplicated_rows ${out2}
mv beforeLiftoverFiltering_executionorder ${out3}


#if [ "${applyFilter}" == "yes" ]
#then
#  #resort to same as input, which is first column containing GRCh38 (not, it is likely that future input also will be sorted on first column)
#  LC_ALL=C sort -k1,1 gb_unique_rows > gb_unique_rows_sorted
#else
#  #make output same as input
#  mv gb_unique_rows gb_unique_rows_sorted
#fi
#

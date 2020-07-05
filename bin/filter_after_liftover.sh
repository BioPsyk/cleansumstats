liftedandmapped=$1
filtering=$2

#split comma separated list into bash array
filterArr=($(echo "${filtering}" | awk '{gsub(/ /, "", $0); print}' | awk '{gsub(/,/, "\n", $0); print}' ))


touch desc_removed_duplicated_rows
touch removed_duplicated_rows
touch afterLiftoverFiltering_executionorder

cp ${liftedandmapped} gb_unique_rows

#loop over bash array applying each correspondinng filtering type in the samee order
for var in ${filterArr[@]}; do

  if [ "${var}" == "duplicated_chrpos_refalt_in_GRCh37" ]
  then

    #remove all but the first ecnountered row where chr:pos REF and ALT for GRCh37
    LC_ALL=C sort -k2,2 -k5,5 -k6,6 gb_unique_rows > gb_unique_rows_sorted
    awk 'BEGIN{r0="initrowhere"} {var=$2"-"$5"-"$6; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_GRCh37"}; r0=var}' gb_unique_rows_sorted > gb_unique_rows2
    awk -vOFS="\t" '{print $3,"duplicated_rows_GRCh37"}' removed_duplicated_rows_GRCh37 >> removed_duplicated_rows
    #process before and after stats
    rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to chr:pos and dbsnp REF/ALT, GRCh37" >> desc_removed_duplicated_rows
    mv gb_unique_rows2 gb_unique_rows
    echo "duplicated_chrpos_refalt_in_GRCh37" >> afterLiftoverFiltering_executionorder

  elif [ "${var}" == "duplicated_chrpos_refalt_in_GRCh38" ]
  then
    #remove all but the first ecnountered row where chr:pos REF and ALT for GRCh38
    LC_ALL=C sort -k1,1 -k5,5 -k6,6 gb_unique_rows > gb_unique_rows_sorted
    touch removed_duplicated_rows_GRCh38
    awk 'BEGIN{r0="initrowhere"} {var=$1"-"$5"-"$6; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_GRCh38"}; r0=var}' gb_unique_rows_sorted > gb_unique_rows2
    awk -vOFS="\t" '{print $3,"duplicated_rows_GRCh38"}' removed_duplicated_rows_GRCh38 >> removed_duplicated_rows
    rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to chr:pos and dbsnp REF/ALT, GRCh38" >> desc_removed_duplicated_rows
    mv gb_unique_rows2 gb_unique_rows
    echo "duplicated_chrpos_refalt_in_GRCh38" >> afterLiftoverFiltering_executionorder
  
  elif [ "${var}" == "duplicated_chrpos_in_GRCh37" ]
  then
    #Filter only on position duplicates (A very hard filter but is good enough for alpha release)
    LC_ALL=C sort -k2,2 gb_unique_rows > gb_unique_rows_sorted
    touch removed_duplicated_rows_GRCh37_hard
    awk 'BEGIN{r0="initrowhere"} {var=$2; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_GRCh37_hard"}; r0=var}' gb_unique_rows_sorted > gb_unique_rows2
    awk -vOFS="\t" '{print $3,"duplicated_rows_GRCh37_hard"}' removed_duplicated_rows_GRCh37_hard >> removed_duplicated_rows
    rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to only chr:pos, GRCh37" >> desc_removed_duplicated_rows
    mv gb_unique_rows2 gb_unique_rows
    echo "duplicated_chrpos_in_GRCh37" >> afterLiftoverFiltering_executionorder
  
  elif [ "${var}" == "duplicated_chrpos_in_GRCh38" ]
  then
    #Filter only on position duplicates (A very hard filter but is good enough for alpha release)
    LC_ALL=C sort -k1,1 gb_unique_rows > gb_unique_rows_sorted
    touch removed_duplicated_rows_GRCh38_hard
    awk 'BEGIN{r0="initrowhere"} {var=$1; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_GRCh38_hard"}; r0=var}' gb_unique_rows_sorted > gb_unique_rows2
    awk -vOFS="\t" '{print $3,"duplicated_rows_GRCh38_hard"}' removed_duplicated_rows_GRCh38_hard >> removed_duplicated_rows
    rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to only chr:pos, GRCh38" >> desc_removed_duplicated_rows
    mv gb_unique_rows2 gb_unique_rows
    echo "duplicated_chrpos_in_GRCh38" >> afterLiftoverFiltering_executionorder
  
  elif [ "${var}" == "multiallelics_in_dbsnp" ]
  then
    #Filter on presence of comma in alt allele column, if so, it is by definition a multiallelic in dbsnp
    touch removed_multiallelic_rows
    awk -vFS="\t" -vOFS="\t" '{if($6 ~ /,/){print > "removed_multiallelic_rows"}else{print $0} }' gb_unique_rows_sorted > gb_unique_rows2
    awk -vOFS="\t" '{print $3,"multiallelic_in_dbsnp"}' removed_multiallelic_rows >> removed_duplicated_rows
    rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved multi-allelics" >> desc_removed_duplicated_rows
    mv gb_unique_rows2 gb_unique_rows
    echo "multiallelics_in_dbsnp" >> afterLiftoverFiltering_executionorder
  
  fi

done

#resort to same as input, which is first column containing GRCh38 (at least now when this comment is written. 2020-07-05)
LC_ALL=C sort -k1,1 gb_unique_rows > gb_unique_rows_sorted

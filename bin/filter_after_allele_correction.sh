acorrected=$1
filtering=$2

#split comma separated list into bash array
filterArr=($(echo "${filtering}" | awk '{gsub(/ /, "", $0); print}' | awk '{gsub(/,/, "\n", $0); print}' ))


touch desc_removed_duplicated_rows
touch removed_duplicated_rows
touch afterAlleleCorrection_executionorder

cp ${acorrected} ac_unique_rows

#loop over bash array applying each correspondinng filtering type in the samee order
for var in ${filterArr[@]}; do

  if [ "${var}" == "duplicated_chrpos_in_GRCh37" ]
  then

    #sort on fourth column (to be able to detect duplicates)
    LC_ALL=C sort -k4,4 $ac_unique_rows > ac_acorrected_sorted_on_chrpos

    #Filter only on position duplicates (A very hard filter but is good enough for alpha release)
    #removes all but the first encountered unique chr:pos row (seems some chrpos that mapped to more than one rsid are caught here)
    touch removed_duplicated_rows_GRCh37_hard
    awk 'BEGIN{r0="initrowhere"} {var=$4; if(r0!=var){print $0}else{print $0 > "removed_afterAlleleCorrection_duplicated_rows_GRCh37_hard"}; r0=var}' ac_unique_rows > ac_unique_rows2
    awk -vOFS="\t" '{print $1,"afterAlleleCorrection_duplicated_rows_GRCh37_hard"}' removed_afterAlleleCorrection_duplicated_rows_GRCh37_hard >> removed_duplicated_rows

    rowsBefore="$(wc -l ac_unique_rows | awk '{print $1-1}')"
    rowsAfter="$(wc -l ac_unique_rows2 | awk '{print $1-1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to only chr:pos, GRCh37" >> desc_removed_duplicated_rows
    mv ac_unique_rows2 ac_unique_rows
    echo "duplicated_chrpos_in_GRCh37" >> afterAlleleCorrection_executionorder

    #re-sort on first column (to get back to same sorting as input)
    #If we get more than one option for this filtering then it might be worth doing this sorting only ones in the end
    LC_ALL=C sort -k1,1 ac_unique_rows > ac_unique_rows_sorted

  fi
done




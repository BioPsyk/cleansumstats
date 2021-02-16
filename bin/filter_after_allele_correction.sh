acorrected=$1
filtering=$2
outfileprefix=$3

#split comma separated list into bash array
filterArr=($(echo "${filtering}" | awk '{gsub(/ /, "", $0); print}' | awk '{gsub(/,/, "\n", $0); print}' ))


touch "${outfileprefix}desc_removed_duplicated_rows"
touch "${outfileprefix}removed_duplicated_rows"
touch "${outfileprefix}afterAlleleCorrection_executionorder"

#copy input to not break anything
cp ${acorrected} ${outfileprefix}ac_unique_rows

#check if no filtering will be applied
if [ "${#filterArr[@]}" -eq 0 ]
then
  applyFilter="no"
else
  applyFilter="yes"
fi

#loop over bash array applying each correspondinng filtering type in the same order
for var in ${filterArr[@]}; do

  if [ "${var}" == "duplicated_chrpos_in_GRCh38" ]
  then

    #sort on fourth column (to be able to detect duplicates)
    LC_ALL=C sort -k4,4 ${outfileprefix}ac_unique_rows > ${outfileprefix}ac_acorrected_sorted_on_chrpos

    #Filter only on position duplicates (A very hard filter but is good enough for alpha release)
    #removes all but the first encountered unique chr:pos row (seems some chrpos that mapped to more than one rsid are caught here)
    touch ${outfileprefix}removed_duplicated_rows_GRCh38_hard
    awk -vpre="${outfileprefix}" 'BEGIN{r0="initrowhere"} {var=$4; if(r0!=var){print $0}else{print $0 > pre"removed_afterAlleleCorrection_duplicated_rows_GRCh38_hard"}; r0=var}' ${outfileprefix}ac_unique_rows > ${outfileprefix}ac_unique_rows2
    awk -vOFS="\t" -vpre="${outfileprefix}" '{print $1,"afterAlleleCorrection_duplicated_rows_GRCh38_hard"}' ${outfileprefix}removed_afterAlleleCorrection_duplicated_rows_GRCh38_hard >> ${outfileprefix}removed_duplicated_rows

    rowsBefore="$(wc -l ${outfileprefix}ac_unique_rows | awk '{print $1-1}')"
    rowsAfter="$(wc -l ${outfileprefix}ac_unique_rows2 | awk '{print $1-1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to only chr:pos, GRCh38" >> ${outfileprefix}desc_removed_duplicated_rows
    mv ${outfileprefix}ac_unique_rows2 ${outfileprefix}ac_unique_rows
    echo "duplicated_chrpos_in_GRCh38" >> ${outfileprefix}afterAlleleCorrection_executionorder


  fi
done

if [ "${applyFilter}" == "yes" ]
then
  #re-sort on first column (to get back to same sorting as input)
  LC_ALL=C sort -k1,1 ${outfileprefix}ac_unique_rows > ${outfileprefix}ac_unique_rows_sorted
else
  #make output same as input
  mv ${outfileprefix}ac_unique_rows ${outfileprefix}ac_unique_rows_sorted
fi


sfile=$1
select=$2
select_return_names=$3
se_column_id="$4"
exclude_columns_ids="${5}"


if [[ $(wc -l $sfile | awk '{print $1}') == "1" ]]
then
  echo "[ERROR] The inputted file sfile did not have any data"
  exit 1
fi

touch numeric_filter_stats__removed_stat_non_numeric_in_awk
touch numeric_filter_stats__removed_stat_non_numeric_in_awk_ix
#sstools-utils ad-hoc-do -f $sfile -k "${select}" -n "${select_return_names}" | \
sstools-utils ad-hoc-do -f $sfile -k "${select}" -n "${select_return_names}" > debugfile

cat debugfile | filter_stat_values_awk.sh \
    -vzeroSE="${se_column_id}" \
    -vcolumskip="${exclude_columns_ids}" \
    > numeric_filter_stats__st_filtered_remains \
    2> numeric_filter_stats__removed_stat_non_numeric_in_awk

if [[ $(wc -l numeric_filter_stats__st_filtered_remains | awk '{print $1}') == "1" ]]
then
  echo "[ERROR] The file numeric_filter_stats_st_filtered_remains did not have any data"
  exit 1
fi

awk '{print $1,"stat_non_numeric_in_awk"}' numeric_filter_stats__removed_stat_non_numeric_in_awk > numeric_filter_stats__removed_stat_non_numeric_in_awk_ix



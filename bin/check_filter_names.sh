filtering=$1
filteringAllowedNames=$2
OUT_log=$3

function variableMissing(){
  if grep -Pq "${1}" ${2}
  then
      echo false
  else
      echo true
  fi
}

#split comma separated list into bash array
filterArr=($(echo "${filtering}" | awk '{gsub(/ /, "", $0); print}' | awk '{gsub(/,/, "\n", $0); print}' ))

#check if no filteringNames are in the list (activate if needed)
#if [ "${#filterArr[@]}" -eq 0 ]
#then
#  applyFilter="no"
#else
#  applyFilter="yes"
#fi

#check if a variable is not found
test_result1=$(
  filter_var_notFound="ok"
  for var in ${filterArr[@]}; do
  
    if [ $(variableMissing "^${var}" ${filteringAllowedNames}) == "true" ]
    then
      filter_var_notFound="fail ::: filter not allowed: ${var}    See file ${filteringAllowedNames} for the list of allowed names"
    else
      :
    fi
  done
  echo $filter_var_notFound
)

if [ $? == 0  ]; then
 test_result2="ok"
 echo "filter-not-in-list-check1 ${test_result1}" >> ${OUT_log}
 echo "filter-not-in-list-check2 ok" >> ${OUT_log}
else
 test_result2="fail"
 echo "filter-not-in-list-check1 ${test_result1}" >> ${OUT_log}
 echo "filter-not-in-list-check2 fail" >> ${OUT_log}
fi

if [ $test_result1 == "ok" ]
then
  #echo >&2 "all seems ok with the meta data format"
  exit 0
else
  echo >&2 "one or more problems detected with the filter names format"
  exit 1
fi


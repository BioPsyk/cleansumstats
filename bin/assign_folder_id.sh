libdir=$1
# Check which ID is free
dirs=($(ls ${libdir}))

newVal=$(for i in "${dirs[@]}"
do
   echo "${i#sumstat_}"
done | awk -vmax="0" '{if($1>=max){max=$1}} END{print max+1} ')

newFolder="sumstat_${newVal}"
echo "${newFolder}"

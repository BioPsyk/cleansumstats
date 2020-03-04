gbmax=$1
GRChsorted=$2
db35=$3
db36=$4
db37=$5
db38=$6


if [ "${gbmax}" == "GRCh38" ] ; then 
  LC_ALL=C join -1 1 -2 1 $GRChsorted ${db38} | awk -vFS="[[:space:]]" -vOFS="\t" '{print $1,$2,$4,$5,$6}' 
elif [ "${gbmax}" == "GRCh37" ] ; then
  LC_ALL=C join -1 1 -2 1 $GRChsorted ${db37} | awk -vFS="[[:space:]]" -vOFS="\t" '{print $3,$2,$4,$5,$6}'
elif [ "${gbmax}" == "GRCh36" ] ; then
  LC_ALL=C join -1 1 -2 1 $GRChsorted ${db36} | awk -vFS="[[:space:]]" -vOFS="\t" '{print $4,$2,$5,$6,$7}'
elif [ "${gbmax}" == "GRCh35" ] ; then
  LC_ALL=C join -1 1 -2 1 $GRChsorted ${db35} | awk -vFS="[[:space:]]" -vOFS="\t" '{print $4,$2,$5,$6,$7}'
else 
  echo "${gbmax} none of the available builds 35, 36, 37 or 38"
fi


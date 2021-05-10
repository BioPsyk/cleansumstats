rsidprep=$1
snpExists=$2
beforeLiftoverFilter=$3
out1=$4
out2=$5
out3=$6

if [ "${snpExists}" == "true" ]
then
  filter_before_liftover.sh ${rsidprep} ${beforeLiftoverFilter} "${out1}" "${out2}" "${out3}"
else
  # Make empty file (should not have header)
  touch ${out1}
  touch ${out2}
  touch ${out3}
fi


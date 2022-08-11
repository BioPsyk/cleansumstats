infile=${1}
pcol=${2}

# Get index on P value column
ix="$(head -n1 ${infile} | awk -vpcol="${pcol}" 'NR==1{for(i=1; i <= NF; i++){if($i==pcol){print i}}}')"

echo -e "pval_from_log10p" > functiontestfile2.txt
cat ${infile} | r-stats-c-streamer --functionfile functiontestfile2.txt --skiplines 1 --index 1 --pvalue ${ix} --statmodel none --replace ${ix} 


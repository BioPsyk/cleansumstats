sfile=$1
suffix=$2

awk -vFS="\t" -vOFS="\t" -vsuffix="${suffix}" 'NR==1{printf "%s%s", "0", OFS; for(k=2; k <= NF-1; k++){printf "%s%s%s", $k, suffix, OFS}; printf "%s%s\n", $NF, suffix}; NR>1{print $0} ' $sfile


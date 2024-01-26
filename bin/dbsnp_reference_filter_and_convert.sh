mapfile=$1
chrtype=$2

if [ "${chrtype}" == "ncbi" ]; then
# Potential NCBI prefixes are removed in this step.
awk -vFS="\t" -vOFS="\t" '
NR==FNR { 
  keys[$1] 
  next 
}
($1 in keys) { 
  gsub("NC_0+", "", $1)
  gsub("\\..*", "", $1)
  if($1=="12920"){$1=26} 
  print $0 }
' ${mapfile} - 
else
  :
fi


dbsnp_chunk=$1
chain=$2
cid=$3
out=$4

#for some reason I have to copy the chain file to the wd for it to be found
cp ${chain} chain2.gz

# Map to GRCh37
CrossMap.py bed chain2.gz ${dbsnp_chunk} "${cid}_tmp"
awk '{tmp=$1; sub(/[cC][hH][rR]/, "", tmp); print $1, $2, $3, tmp":"$2, $4, $5, $6, $7}' "${cid}_tmp" > ${out}

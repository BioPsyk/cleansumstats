dbsnp_chunk=$1
chain=$2
cid=$3
out=$4
fasta=$5

# For some reason I have to copy the chain file to the wd for it to be found
cp ${chain} chain2.gz

# Copy also the fasta and its index file
cp ${fasta} ref.fasta.bgz
cp ${fasta}.fai ref.fasta.bgz.fai
cp ${fasta}.gzi ref.fasta.bgz.gzi

# Map to GRCh37
CrossMap.py vcf chain2.gz ${dbsnp_chunk} ref.fasta.bgz ${cid}_tmp

awk '{tmp=$1; sub(/[cC][hH][rR]/, "", tmp); print $1, $2, $3, tmp":"$2, $4, $5, $6, $7}' "${cid}_tmp" > ${out}


#make 0-position (but it appears not as simple to make +1 after the liftover)
#awk '{$2=$2-1;$3=$3-1;print $0}' ${dbsnp_chunk} > ${cid}_pos_tmp

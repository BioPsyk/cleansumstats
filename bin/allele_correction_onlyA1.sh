sfile=$1
mapped=$2
colA1=$3
primary_out1=$4
extra_out2=$5

echo -e "0\tA1\tA2\tCHRPOS\tRSID\tEffectAllele\tOtherAllele\tEMOD" > ${primary_out1}

#init some the files collecting variants removed because of allele composition
touch removed_notGCTA
touch removed_indel
touch removed_hom
touch removed_palin
touch removed_notPossPair
touch removed_notExpA2

cat ${sfile} | sstools-utils ad-hoc-do -k "0|${colA1}" -n"0,A1" | LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 2.2 2.3 2.4 2.5 -1 1 -2 1 - ${mapped} | tail -n+2 | sstools-eallele correction -f - -a >> ${primary_out1}

#only keep the index to prepare for the file with all removed lines
touch ${extra_out2}
awk -vOFS="\t" '{print $1,"notGCTA"}' removed_notGCTA >> ${extra_out2}
awk -vOFS="\t" '{print $1,"indel"}' removed_indel >> ${extra_out2}
awk -vOFS="\t" '{print $1,"hom"}' removed_hom >> ${extra_out2}
awk -vOFS="\t" '{print $1,"palin"}' removed_palin >> ${extra_out2}
awk -vOFS="\t" '{print $1,"notPossPair"}' removed_notPossPair >> ${extra_out2}
awk -vOFS="\t" '{print $1,"notExpA2"}' removed_notExpA2 >> ${extra_out2}


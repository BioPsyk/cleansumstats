sfile=$1
mapped=$2
colA1=$3
colA2=$4
primary_out1=$5
extra_out2=$6

echo -e "0\tA1\tA2\tCHRPOS\tRSID\tEffectAllele\tOtherAllele\tEMOD" > ${primary_out1}

#init some the files collecting variants removed because of allele composition
touch removed_notGCTA
touch removed_indel
touch removed_hom
touch removed_palin
touch removed_notPossPair
touch removed_notExpA2

#colA1=\$(map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "effallele")
#colA2=\$(map_to_adhoc_function.sh ${ch_regexp_lexicon} ${sfile} "altallele")
cat ${sfile} | sstools-utils ad-hoc-do -k "0|${colA1}|${colA2}" -n"0,A1,A2" | LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 1.3 2.2 2.3 2.4 2.5 -1 1 -2 1 - ${mapped} | tail -n+2 | sstools-eallele correction -f - >> ${primary_out1}

#only keep the index to prepare for the file with all removed lines
touch allele_correction_A1_A2__removed_allele_filter_ix
awk -vOFS="\t" '{print $1,"notGCTA"}' removed_notGCTA >> ${extra_out2}
awk -vOFS="\t" '{print $1,"indel"}' removed_indel >> ${extra_out2}
awk -vOFS="\t" '{print $1,"hom"}' removed_hom >> ${extra_out2}
awk -vOFS="\t" '{print $1,"palin"}' removed_palin >> ${extra_out2}
awk -vOFS="\t" '{print $1,"notPossPair"}' removed_notPossPair >> ${extra_out2}
awk -vOFS="\t" '{print $1,"notExpA2"}' removed_notExpA2 >> ${extra_out2}


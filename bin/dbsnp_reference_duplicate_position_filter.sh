dbsnp_chunk=${1}
out=${2}
out2=${3}

# Remove all duplicated positions GRCh37 (as some positions might have become duplicates after the liftover)
mkdir -p tmp
LC_ALL=C sort -k 4,4 \
--parallel 4 \
--temporary-directory=/cleansumstats/tmp \
--buffer-size=20G \
${dbsnp_chunk} \
> All_20180418_liftcoord_GRCh37_GRCh38.bed.sorted
rm -r tmp

# Remove all versions of the duplicated variants
awk -vout2="${out2}" 'BEGIN{
  getline; 
  prevrow=$0; 
  prevrowvar=$4; 
  prevrowrm="notremoved"} 
{
  currentvar=$4; 
  if(prevrowvar==currentvar){
    prevrowrm=="removed";
    print prevrow > out2;
  }else if(prevrowrm=="removed"){
    prevrowrm=="notremoved";
    print prevrow > out2;
  }else{
    print prevrow;
  }
prevrowvar=currentvar;
prevrow=$0;
}
END{
  if(prevrowvar==currentvar){
    print prevrow > out2;
  }else if(prevrowrm=="removed"){
    print prevrow > out2;
  }else{
    print prevrow;
  }
}
' All_20180418_liftcoord_GRCh37_GRCh38.bed.sorted > ${out}



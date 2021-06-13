dbsnp_chunk=${1}
out=${2}

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
awk 'BEGIN{
  getline; 
  prevrow=$0; 
  prevrowvar=$4; 
  prevrowrm="notremoved"} 
{
  currentvar=$4; 
  if(prevrowvar==currentvar){
    prevrowrm=="removed";
    print prevrow > "removed_duplicated_rows_GRCh37";
  }else if(prevrowrm=="removed"){
    prevrowrm=="notremoved";
    print prevrow > "removed_duplicated_rows_GRCh37";
  }else{
    print prevrow;
  }
prevrowvar=currentvar;
prevrow=$0;
}
END{
  if(prevrowvar==currentvar){
    print prevrow > "removed_duplicated_rows_GRCh37";
  }else if(prevrowrm=="removed"){
    print prevrow > "removed_duplicated_rows_GRCh37";
  }else{
    print prevrow;
  }
}
' All_20180418_liftcoord_GRCh37_GRCh38.bed.sorted > ${out}



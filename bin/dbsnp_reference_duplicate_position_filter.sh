infile=${1}
out=${2}
out2=${3}
tmpfold=${4}

touch $out
touch $out2

# Remove all duplicated positions in col4 
# purpose to remove positions, which might have become duplicates after liftover
#mkdir -p /cleansumstats/work/sort_tmp
mkdir -p ${tmpfold}
LC_ALL=C sort -k 4,4 \
--parallel 4 \
--temporary-directory=${tmpfold} \
--buffer-size=20G \
${infile} \
> input.sorted

# Remove all versions of the duplicated variants
awk -vout2="${out2}" '
BEGIN{
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
  prevrowvar2=prevrowvar;
  prevrowvar=currentvar;
  prevrow=$0;
}
END{
  if(prevrowvar2==prevrowvar){
    print prevrow > out2;
  }else{
    print prevrow;
  }
}
' input.sorted > ${out}



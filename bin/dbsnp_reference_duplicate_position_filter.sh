infile=${1}
out=${2}
out2=${3}

touch $out
touch $out2

# Remove all duplicated positions in col4 
# purpose to remove positions, which might have become duplicates after liftover
tmp_dir=$(mktemp -d)
LC_ALL=C sort -k 4,4 \
--parallel 4 \
--temporary-directory=${tmp_dir} \
--buffer-size=20G \
${infile} \
> input.sorted
rm -r ${tmp_dir}

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



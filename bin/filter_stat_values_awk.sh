#!/usr/bin/awk -f

function in_NA(field){
  ans=field ~ /[nN][aA]/;
  return ans;
}

BEGIN{
  FS="\t"
  OFS="\t"
}

{
  if(in_NA($0)){
    print $1,"NA" > "/dev/stderr";
  }else{
    print $0
  }
}


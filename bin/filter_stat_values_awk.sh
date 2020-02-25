#!/usr/bin/awk -f

#function in_NA(field){
#  ans=field ~ /[nN][aA]/;
#  return ans;
#}

BEGIN{
  FS="\t"
  OFS="\t"
}

NR==1 {
  print $0
}

NR>1{
  #if(in_NA($0)){
  #  print $1,"NA" > "/dev/stderr";
  #}else{
  #  print $0
  #}

  #check if numeric by trying to add 0, if the value is the same, then print line
  doprint="yes"
  #printf "%s%s", $1, OFS
  for(i=2; i<=NF; i++){

    #check if awk understands how to use math for this value
    if($i != $i+0){
      doprint="no"
    }

    #check if the regexp match a digit
    if($i !~ /[[:digit:]]+/){
      doprint="no"
     # printf "%s%s", $i,OFS
    }
  }
   # print ""

  if(doprint=="no"){
    print $1,"NOT_AWK_NUMERIC" > "/dev/stderr";
  }else{
    print $0
  }
}


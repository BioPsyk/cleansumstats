#!/usr/bin/awk -f

#function in_NA(field){
#  ans=field ~ /[nN][aA]/;
#  return ans;
#}

BEGIN{
  FS="\t"
  OFS="\t"
}

{

 #NOT IN USE RIGTH now

  #check if numeric by trying to add 0, if the value is the same, then print line
 # doprint=1
 # for(i=2; i<=NF; i++){
 #   if($i!=$i+0){
 #     doprint=0
 #   }

 #   if($i !~ /[[:digit:]]+/){
 #     doprint=0
 #   }
 # }

 # if(doprint==0){
 #   print $1,"NOT_AWK_NUMERIC" > "/dev/stderr";
 # }else{
 #   print $0
 # }
}


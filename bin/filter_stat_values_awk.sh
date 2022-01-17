#!/usr/bin/awk -f

#function in_NA(field){
#  ans=field ~ /[nN][aA]/;
#  return ans;
#}

BEGIN{
  FS="\t"
  OFS="\t"
  split(columskip, column_ids_skip, ",");
  # set values as keys
  for (i in column_ids_skip) column_ids_skip2[column_ids_skip[i]] = ""
  #for (i in column_ids_skip2) {
  #  print i, column_ids_skip2[i]
  #}
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
  whyremoved="foobar"
  #printf "%s%s", $1, OFS
  for(i=2; i<=NF; i++){
    #printf "%s%s", $i, "____"
    if(i in column_ids_skip2){
      continue;
    }

    if($i != $i+0){
    #check if awk understands how to use math for this value
      doprint="no"
      whyremoved="AWK_CANT_USE_MATH_HERE"

    }else if($i !~ /[[:digit:]]+/){
    #check if the regexp match a digit
      doprint="no"
      whyremoved="AWK_REGEXP_NO_DIGIT"
     # printf "%s%s", $i,OFS
    }else if(i==zeroSE){
    #for SE if present, check if value is not zero
      if($i == 0){
        doprint="no"
        whyremoved="AWK_REGEXP_NO_DIGIT"
       # printf "%s%s", $i,OFS
      }
    }
  }
  if(doprint=="no"){
    print $1, whyremoved > "/dev/stderr";
  }else{
    print $0
  }
}


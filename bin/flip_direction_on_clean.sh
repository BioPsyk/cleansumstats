#!/usr/bin/env bash

# NOTE: This only works as long as at least one stat field is present. When writing this script, that is also the requirement of the cleansumstats main script.

infile="${1}"
outfile="${2}"
maf="${3}"



header="$(zcat $infile | head -n1)"

#recode as true or false
function var_exists(){
  var=$1
  echo ${header} | awk '{print $0" "}'1 | grep -q "[[:space:]]$var[[:space:]]"
}

function var_col(){
  var=$1
  echo ${header} | awk -vvar="${var}" '{for (i=1;i<=NF;++i){if(var==$i){print i}}}' 
}
#Which columns should have
#1*var
modc1="$(for var in "B" "Z"; do
if var_exists "${var}"; then
  var_col "${var}"
fi
done | awk '{printf "%s|", $1}' | sed 's/|$//')"


#1-var
modc2="$(for var in EAF CaseEAF ControlEAF EAF_1KG EAS EUR AFR AMR SAS; do
if var_exists "${var}"; then
  var_col "${var}"
fi
done | awk '{printf "%s|", $1}' | sed 's/|$//')"

##1/var
modc3="$(for var in OR; do
if var_exists "${var}"; then
  var_col "${var}"
fi
done | awk '{printf "%s|", $1}' | sed 's/|$//')"


# Check if we use the maf version of this script
  maf_given=false
  eaf_cnr=0
if [ -z "${maf}" ]
then
  awk \
    -vOFS="\t" \
    -vmod1="${modc1}" \
    -vmod2="${modc2}" \
    -vmod3="${modc3}" \
  '
  BEGIN{
    split(mod1,m1a,"|");
    split(mod2,m2a,"|");
    split(mod3,m3a,"|");
    for (h in m1a){m1[m1a[h]]++};
    for (h in m2a){m2[m2a[h]]++};
    for (h in m3a){m3[m3a[h]]++};
  }
  
  NR==1{
    print $0
  }
  NR>1{
    for (i=1;i<5;++i){
      printf "%s%s", $(i), OFS;
    }
    printf "%s%s", $(6), OFS;
    printf "%s%s", $(5), OFS;
    for (i=7;i<NF;++i){
      if(i in m1){printf "%s%s", -1*$(i), OFS}
      else if(i in m2){printf "%s%s", 1-$(i), OFS}
      else if(i in m3){printf "%s%s", 1/$(i), OFS}
      else{printf "%s%s", $(i), OFS};
    }
    if(NF in m1){printf "%s%s", 1*$NF, RS}
    else if(NF in m2){printf "%s%s", 1-$NF, RS}
    else if(NF in m3){printf "%s%s", 1/$NF, RS}
    else{printf "%s%s", $NF, RS};
  }
  ' <(zcat ${infile}) | gzip -c > ${outfile}
else
  if [ "${maf}" == "maf" ]; then
    if var_exists "EAF"; then
      eaf_cnr=$(var_col "EAF")

      awk \
        -vOFS="\t" \
        -vmod1="${modc1}" \
        -vmod2="${modc2}" \
        -vmod3="${modc3}" \
        -veafcnr="${eaf_cnr}" \
      '
      BEGIN{
        split(mod1,m1a,"|");
        split(mod2,m2a,"|");
        split(mod3,m3a,"|");
        for (h in m1a){m1[m1a[h]]++};
        for (h in m2a){m2[m2a[h]]++};
        for (h in m3a){m3[m3a[h]]++};
      }
      
      NR==1{
        print $0
      }
      NR>1{
        if($(eafcnr)>0.5){
          for (i=1;i<5;++i){
            printf "%s%s", $(i), OFS;
          }
          printf "%s%s", $(6), OFS;
          printf "%s%s", $(5), OFS;
          for (i=7;i<NF;++i){
            if(i in m1){printf "%s%s", -1*$(i), OFS}
            else if(i in m2){printf "%s%s", 1-$(i), OFS}
            else if(i in m3){printf "%s%s", 1/$(i), OFS}
            else{printf "%s%s", $(i), OFS};
          }
          if(NF in m1){printf "%s%s", 1*$NF, RS}
          else if(NF in m2){printf "%s%s", 1-$NF, RS}
          else if(NF in m3){printf "%s%s", 1/$NF, RS}
          else{printf "%s%s", $NF, RS};
        }else{
          print $0
        }
      }
      ' <(zcat ${infile}) | gzip -c > ${outfile}

    else
      echo "no EAF column, which is required when using the maf option"
    fi
  else
    echo "leave empty or set to: maf"
    exit 1
  fi
fi



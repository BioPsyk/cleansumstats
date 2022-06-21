STAT=${1}
ACOR=${2}

function selRightHand(){
  echo "${1#*: }"
}
function selColRow(){
  grep ${1} ${2}
}

function stat_exists(){
  var=$1
  fl=$2
  head -n1 $fl | awk '{print $0" "}'1 | grep -q "[[:space:]]$var[[:space:]]"
}
function stat_coln(){
  var=$1
  fl=$2
  head -n1 $fl | awk -vregexp="@/ *${var} */" '{for(i=1; i<=NF; i++){if($(i) ~ regexp){print i+1}}}'
}

#return colposition in file
function which_to_mod1(){
    if stat_exists "B" ${STAT}; then
      stat_coln "B" ${STAT}
    fi
    if stat_exists "Z" ${STAT}; then
      stat_coln "Z" ${STAT}
    fi
}

function which_to_mod2(){
    if stat_exists "EAF" ${STAT}; then
      stat_coln "EAF" ${STAT}
    fi
}

function which_to_mod3(){
    if stat_exists "OR" ${STAT}; then
      stat_coln "OR" ${STAT}
    fi
}

#Add emod to stats and then ->
#Flip the different selections in respect to emod
unset var_k var_m var_m2 var_m3
var_m1=$(which_to_mod1 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
var_m2=$(which_to_mod2 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
var_m3=$(which_to_mod3 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
awk -vOFS="\t" -vm1=${var_m1} -vm2=${var_m2} -vm3=${var_m3} '
BEGIN{
  #split and change to values as keys
  split(m1,a1,"|")
  for (i in a1) b1[a1[i]] = ""
  split(m2,a2,"|")
  for (i in a2) b2[a2[i]] = ""
  split(m3,a3,"|")
  for (i in a3) b3[a3[i]] = ""
}
NR==1{
  printf "%s", $1
  for(i=3; i<=NF; i++){printf "%s%s", OFS, $(i)}
  printf "%s", RS;
}
NR>1{
  printf "%s", $1
  for(i=3; i<=NF; i++){
    if(i in b1){printf "%s%s", OFS, $(i)*$2}
    else if(i in b2 && $2=="-1" && $(i)!="NA"){printf "%s%s", OFS, 1-$(i)}
    else if(i in b3 && $2=="-1"){printf "%s%s", OFS, 1/$(i)}
    else {printf "%s%s", OFS, $(i)}
  }
  printf "%s", RS;
}
' <(LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 <(awk -vFS="\t" -vOFS="\t" '{print $1,$8}' ${ACOR}) ${STAT})


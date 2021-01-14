default=$1
other=$2

function stat_exists(){
  var=$1
  infs=$2
  head -n1 $infs | grep -q "[[:space:]]$var[[:space:]]"
}

#loop through header of kgaf and if missing in default then
headerOther=($(head -n1 $other | awk '
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }

NR==1{tr=trim($0); print tr}')) 

#Loop through all headerOther values, return the ones that are not present in the other
for hc in ${headerOther[@]}; do
  #echo $hc
  if [ $(stat_exists ${hc} ${default}) ]
  then
    :
  else
    ${hc}
  fi
done | awk '{printf "%s|", $1}' | sed 's/|$//'




function autoRegexpFromMeta(){
  allowedfile=$1
  mapfile=$2
  ssfile=$3
  colType=$4

  function selRightHand(){
    echo "${1#*: }"
  }

  function selColRow(){
    grep ${1} ${2}
  }

  if [ $colType == "chr" ]; then
    colTypeCol=2
    colVal="$(selRightHand "$(selColRow "^col_CHR:" ${mapfile})")"
  elif [ $colType == "bp" ]; then
    colTypeCol=3
    colVal="$(selRightHand "$(selColRow "^col_POS:" ${mapfile})")"
  elif [ $colType == "effallele" ]; then
    colTypeCol=4
    colVal="$(selRightHand "$(selColRow "^col_EffectAllele:" ${mapfile})")"
  elif [ $colType == "altallele" ]; then
    colTypeCol=5
    colVal="$(selRightHand "$(selColRow "^col_OtherAllele:" ${mapfile})")"
  else
    echo "Error: cant find colType" 1>&2
  fi

  >&2 echo "colVal: ${colTypeCol}"
  >&2 echo "colVal: ${colVal}"

  #detect inputtype using regexp on column
  >&2 cat ${ssfile} | sstools-utils ad-hoc-do -k "${colVal}" -n"Val" | head -n2

  val=$(cat ${ssfile} | sstools-utils ad-hoc-do -k "${colVal}" -n"Val" | head -n2 | tail -n1)
  >&2 echo "val: ${val}"

  function colTypeFound(){
    if echo "${2}" | grep -Pwq "${1}"
    then
        echo true
    else
        echo false
    fi
  }

  #check that it did not return multiple values
  function stop_if_more_or_less_than_1(){
    ar=($@)
    le=${#ar[@]}
    #echo $le
      if [ "${le}" == "1" ]
      then
       # exit 0
       :
      elif [ "${le}" == "0" ]
      then
        echo "The entry had no matches among allowed regexp, and so the error is likely on the user end" 1>&2
       # exit 1
      else
        echo "The entry had multiple matches (N=${le}) among allowed regexp, but there should only be one match! The allowed regexp file has to be updated" 1>&2
       # exit 1
      fi
  }

  #loop over each row in allowed types file and select the matching formula
  function map_to_function(){
    val=$1
    allowedTypesFile=$2
    j=$3

    allowedType1=($(tail -n+2 ${allowedTypesFile} | awk -vFS="\t" '{print $1}' ))
    allowedType2=($(tail -n+2 ${allowedTypesFile} | awk -vi="${j}" -vFS="\t" '{print $i}' ))

    len=${#allowedType1[@]}
    for (( i=0; i<=$len; i++ )); do
     # echo "${allowedType1[${i}]}"
     # echo "${allowedType2[${i}]}"

      at="${allowedType1[${i}]}"
      if [ $(colTypeFound "${at}" "${val}") == "true" ]
      then
        echo "${allowedType2[${i}]}"
      else
        :
      fi
    done
  }

  #
  map1="$(map_to_function $val $allowedFile ${colTypeCol})"
  stop_if_more_or_less_than_1 "${map1}"

  #use mapped funx to get correct value
  echo "${map1}(${colVal})"

}
allowedFile=${1}
mapfile=${2}
ssfile=${3}
colType=${4}

autoRegexpFromMeta ${allowedFile} ${mapfile} ${ssfile} ${colType}

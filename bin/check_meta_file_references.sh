pathToCheck=$1
mfile=$2
metaDir=$3

# Check if field for sumstat exists
failures=0
if grep -q "^${pathToCheck}=" $mfile; then
  
  grep "^${pathToCheck}=" $mfile | while read -r Pathx ; do
    spath1="${Pathx#*=}"
    #check if missing
    if [ "${spath1}" == "missing" ] ; then
      echo "missing"
    else
      # Check if file specified exists
      spath2="${metaDir}/${spath1}"
      if [ -f "$spath1" ] ;then
        echo "${spath1}"
      elif [ -f "$spath2" ]; then 
        echo "${spath2}"
      else
        echo 1>&2 "the file ${spath1} doesnt exist, which is pointed at in the metafile '${pathToCheck}=' field"
        exit 1
      fi
    fi
    ret=$?
    ((ret == 0))
  done
  ret=$?
  if [ "${ret}" == "0" ]
  then
    exit 0
  else
    exit 1
  fi
else
  echo 1>&2 "the '${pathToCheck}=' field does not exist in the metafile"
  exit 1
fi

#echo 1>&2 "HEJ${failures}"

#if [ "${failures}" == "0" ]
#then
#  exit 0
#else
#  exit 1
#fi

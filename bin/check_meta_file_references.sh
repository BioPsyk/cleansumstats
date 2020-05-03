pathToCheck=$1
mfile=$2
metaDir=$3

# Check if field for sumstat exists
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
        echo "the file ${spath1} doesnt exist, which is pointed at in the metafile '${pathToCheck}=' field"
        exit 1
      fi
    fi
  done
  exit 0
else
  echo "the '${pathToCheck}=' field does not exist in the metafile"
  exit 1
fi


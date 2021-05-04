mfile=$1
mfile2=$2

# Use dos2unix
# Use sed to capture more strange cases
cat ${mfile} | dos2unix | sed 's/\\r$//' > ${mfile2}


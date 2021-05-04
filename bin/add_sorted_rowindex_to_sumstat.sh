infile=$1
cat $infile | sstools-raw add-index | LC_ALL=C sort -k1,1


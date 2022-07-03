indir=$1
suffix=$2

# Scan through all subdirs for metafiles to use 
# Use suffix to select only files of interest
/cleansumstats/bin/metadata_to_table.py ${indir}/*/*${suffix}


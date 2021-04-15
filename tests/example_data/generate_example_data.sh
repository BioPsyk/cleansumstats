# Take a few metafiles from alpha library
sslib="~/IBP_pipeline_cleansumstats_alpha/cleansumstats_v1.0.0-alpha/sumstat_library"
sspdfs="~/home/jesgaaopen/IBP_pipeline_cleansumstats_alpha/cleansumstats_v1.0.0-alpha/sumstat_pdfs"
out="out"

seedval=1337
openssl enc -aes-256-ctr -pass pass:"$seedval" -nosalt </dev/zero 2>/dev/null | head -10000 > random_seed_file_source

for id in {1..5}; do
 mkdir -p "out/sumstat_${id}"
 zcat ${sslib}/sumstat_${id}/sumstat_${id}_raw.gz | sort -R --random-source=${random_seed_file_source} | head -n 1000 | gzip -c > out/sumstat_${id}/sumstat_${id}_raw.gz
 cp ${sslib}/sumstat_${id}/sumstat_${id}_raw_meta.txt out/sumstat_${id}/sumstat_${id}_raw_meta.txt

 if [ -f "${sslib}/sumstat_${id}/sumstat_${id}_raw_README.txt" ]; then
   cp ${sslib}/sumstat_${id}/sumstat_${id}_raw_README.txt out/sumstat_${id}/sumstat_${id}_raw_README.txt
 fi

 # Because of broken symlinks we have to use pattern matching
 pmid="$(ls ${sslib}/sumstat_${id}/sumstat_*_pmid*pdf | awk '{gsub(/.*sumstat_.*pmid_/,"");gsub(/.pdf/,"")}1')"
 cp ${sspdfs}/pmid_${pmid}.pdf out/sumstat_${id}/sumstat_${id}_pmid_${pmid}_pdf
 cp -r ${sspdfs}/pmid_${pmid}_supp out/sumstat_${id}/sumstat_${id}_pmid_${pmid}_supp

 # Use dummy pdfs in case needed as example data in repo
 echo "placeholder file as a pdf is too large, and wouldn't be used by the pipelinen other than being copied" > tmp
 mv tmp out/sumstat_${id}/sumstat_${id}_pmid_${pmid}_pdf

 # For each file in folder replace with dummy file
 for file in $(ls -1 out/sumstat_${id}/sumstat_${id}_pmid_${pmid}_supp); do
   echo "placeholder file as a pdf is too large, and wouldn't be used by the pipeline other than being copied" > tmp
   mv tmp out/sumstat_${id}/sumstat_${id}_pmid_${pmid}_supp/${file}
 done

done

# Make corresponding dbsnp data sets of small size
dbsnplib="~/home/jesgaaopen/IBP_pipeline_cleansumstats_alpha/cleansumstats_v1.0.0-alpha/sumstat_pdfs"


# Make corresponding 1kgp data set of small size
1kglib="~/home/jesgaaopen/IBP_pipeline_cleansumstats_alpha/cleansumstats_v1.0.0-alpha/sumstat_pdfs"

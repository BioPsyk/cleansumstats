# Post-processing

Here are a series of oneliners to make simple modifications on the output


## Shift coordinates from GRCh38 to GRCh37
The cleaned stats are using the GRCh38 reference build, but it is easy to switch base using the accompanying `cleaned_GRCh37.gz` file. 

```
mkdir -p GRCh37-switch
paste <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh37.gz) <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh38.gz) | cut -f1-2,6- | gzip -c >  GRCh37-switch/cleaned_GRCh37.gz
```
For some positions in GRCh38 there is no representative position for GRCh37. These positions have NA. You can extend the code above to remove these in the same command.
```
paste <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh37.gz) <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh38.gz) | cut -f1-2,6- | awk '$1 != "NA"' | gzip -c >  GRCh37-switch/cleaned_GRCh37.gz
```

## Add total N (effectiveN) from metafile as column N

```
# Extract N to use from metafile
NTOT="$(awk '$1~"stats_EffectiveN:"{print $2}' out_test/sumstat_1_raw_meta/cleaned_metadata.yaml)"

# Add N to output
awk -vFS="\t" -vOFS="\t" -vntot="${NTOT}" 'NR==1{print $0, "N"}; NR>1{print $0, ntot}' <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh38.gz)
```

## Flip effect direction

### flip effect allele from ref to alt allele
The output allele frequency will be reference allele based, i.e., the reference allele will always be the effect allele, with the direction reflected in Z,Beta and OR. If you want to flip all of them you can use the provided post-process script. Be aware that any multiallelics in the original sumstats are sensitive to this flipping, which there is no support for at the moment.
```
./cleansumstats -e -o out_test
./cleanflipdirection.sh out_test/cleaned_GRCh38.gz out_test/cleaned_GRCh38_flipped.gz
```

### flip effect allele to become the maf allele
Requires EAF to be present, and flips if >0.5

```
./cleansumstats -e -o out_test
./cleanflipdirection.sh out_test/cleaned_GRCh38.gz out_test/cleaned_GRCh38_flipped_maf.gz maf
```


## Add 5 main pop AF from 1kgp
Everything that doesn't match gets NA. The output will always be .gz. To get the right direction of effects in respect to effect allele and other allele, we need to apply the effect modifier.
```
./cleansumstats -e -o out_test
./add1kgaf2clean.sh out_test/cleaned_GRCh38.gz tests/example_data/1kgp/generated_reference/1kg_af_ref.txt out_test/details/effect_modifier.gz out_test/cleaned_GRCh38_added5pop.gz
```

## Convert to vcf

To better integrate with other tools we provide a script that converts the cleaned output to a vcf. The stats will all be placed in the FORMAT field, similarly to the output from https://github.com/MRCIEU/gwas2vcf.

```
# Clean data using the example data
./cleansumstats -e -o out_test

# Convert the cleaned output to vcf (with associated tabix index)
# Use REF if it is reference based (default), or ALT if is based on the alternative allele(after flipping effect direction).
mkdir -p vcf
alleleEffect="REF"
refAlleleColumn="5"
altAlleleColumn="6"
./clean2vcf.sh out_test/sumstat_1_raw_meta/cleaned_GRCh38.gz vcf/cleaned_GRCh38.gz "${alleleEffect}" "${refAlleleColumn}" "${altAlleleColumn}"

## Add extra data field

Data that does not depend on anything else than the variant position can safely be added by first constructing a fake sumstat file for cleaning using the info field. That wil make sure we use the same positions when joining with the real sumstat data.

```
# Make fake sumstat
mkdir -p add_extra_field
echo -e "SNP\tCHR\tPOS\tEA\tOA\tBETA\tINFO" > add_extra_field/sumstat_1_raw
zcat tests/example_data/sumstat_1/sumstat_1_raw.gz | LC_ALL=C awk -vFS="\t" -vOFS="\t" 'BEGIN{srand(66)}; NR>1{print $1,$2,$3,$4,$5,"1.5",int(rand()*100)/100}' >> add_extra_field/sumstat_1_raw
gzip add_extra_field/sumstat_1_raw 

cat <<EOF > add_extra_field/sumstat_1_fake.yaml 
cleansumstats_version: 1.0.0
cleansumstats_metafile_user: webform
cleansumstats_metafile_date: '2023-05-17'
cleansumstats_metafile_kind: minimal
path_sumStats: sumstat_1_raw.gz
stats_TraitType: quantitative
stats_Model: linear
stats_TotalN: 10000
stats_GCMethod: none
col_CHR: CHR
col_POS: POS
col_SNP: SNP
col_EffectAllele: EA
col_OtherAllele: OA
col_BETA: BETA
col_INFO: INFO
col_Notes: The beta is made up
EOF

# Clean the fake data we just created
./cleansumstats.sh -e -i add_extra_field/sumstat_1_fake.yaml  -o out_extra_fields_fake

# Clean real data using the example data
./cleansumstats.sh  -e -o out_extra_fields_real

# Add the fake data to the real data using unix join
# Preprocess the files to create a composite field
awk -v OFS="\t" '{print $1"-"$2"-"$5"-"$6,$0}' <(zcat out_extra_fields_fake/cleaned_GRCh38.gz) > temp1
awk -v OFS="\t" '{print $1"-"$2"-"$5"-"$6,$0}' <(zcat out_extra_fields_real/cleaned_GRCh38.gz) > temp2

# Perform the join(keep head unsorted)
(head -n 1 temp1 && tail -n +2 temp1 | sort -k1) > sorted_temp1
(head -n 1 temp2 && tail -n +2 temp2 | sort -k1) > sorted_temp2
join -t $'\t' -1 1 -2 1 sorted_temp2 sorted_temp1 > joined_file

# remove unwanted columns
cut -f 2-12,20 joined_file | gzip -c > final_file.gz

# Clean up temporary files
rm temp1 temp2 sorted_temp1 sorted_temp2 joined_file

```


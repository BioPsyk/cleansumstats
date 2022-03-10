# Post-processing

Here are a series of oneliners to make simple modifications on the output


## Shift coordinates from GRCh38 to GRCh37
The cleaned stats are using the GRCh38 reference build, but it is easy to switch base using the accompanying `cleaned_GRCh37.gz` file. 

```
mkdir -p GRCh37-switch
paste <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh37.gz) <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh38.gz) | cut -f1-2,6- | gzip -c >  GRCh37-switch/cleaned_GRCh37.gz
```

## Add total N (effectiveN) from metafile as column N

```
# Extract N to use from metafile
NTOT="$(awk '$1~"stats_EffectiveN:"{print $2}' out_test/sumstat_1_raw_meta/cleaned_metadata.yaml)"

# Add N to output
awk -vFS="\t" -vOFS="\t" -vntot="${NTOT}" 'NR==1{print $0, "N"}; NR>1{print $0, ntot}' <(zcat out_test/sumstat_1_raw_meta/cleaned_GRCh38.gz)
```

## Flip effect direction
The output allele frequency will be reference allele based, i.e., the reference allele will always be the effect allele, with the direction reflected in Z,Beta and OR. If you want to flip all of them you can use the provided post-process script. Be aware that any multiallelics in the original sumstats are sensitive to this flipping, which there is no support for at the moment.
```
./cleansumstats -e -o out_test
./cleanflipdirection.sh out_test/cleaned_GRCh38.gz out_test/cleaned_GRCh38_flipped.gz
```

## Add 5 main pop AF from 1kgp
Everything that doesn't match gets NA. The output will always be .gz. To get the right direction of effects in respect to effect allele and other allele, we need to apply the effect modifier.
```
./cleansumstats -e -o out_test
./add1kgaf2clean.sh out_test/cleaned_GRCh38.gz tests/example_data/1kgp/generated_reference/1kg_af_ref.sorted.joined out_test/details/effect_modifier.gz out_test/cleaned_GRCh38_added5pop.gz
```

## Convert to vcf

To better integrate with other tools we provide a script that converts the cleaned output to a vcf. The stats will all be placed in the FORMAT field, similarly to the output from https://github.com/MRCIEU/gwas2vcf.

```
# Clean data using the example data
./cleansumstats -e -o out_test

# Convert the cleaned output to vcf (with associated tabix index)
# Use REF if it is reference based (default), or ALT if is based on the alternative allele(after flipping effect direction).
mkdir -p vcf
./clean2vcf.sh out_test/sumstat_1_raw_meta/cleaned_GRCh38.gz vcf/cleaned_GRCh38.gz "REF"

```




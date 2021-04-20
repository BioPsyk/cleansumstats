# Developer instructions
Here we collect developer specific documentation, which never should be expected to be readby a user. Note: in the code there are proposed settings for HPC slurm jobs when the preparations may need parallelization.

## Creating the ibp-pipeline-lib .jar file
Build the ibp-pipeline-lib-x.x.x.jar file accroding to instructions at: https://github.com/BioPsyk/ibp-pipeline-lib, Then place it inside the docker/ directory in the cleansumstats repository to be accessible by the docker build script. To facilitate development and because of the small size of the image, we have decided to store the correct version for this repo in the docker/ directory. If in the future this file becomes too large we might exclude it from the repo.

## Creating "real-life" example data
The purpose of integrating a example data set from real-life data is to make it easy for the user to quickly get familiar with the software by running and inspecting all necessary data. It is also important for the developer to quickly be able to inspect intermediate files when debugging or developing tests or rerouting channels in the workflow. In this section we describe how to do make smaller data sets of all necessary source data:
- sumstats with meta information and files
- dbsnp
- 1000 genome project

### Create sumstat example data from the alpha repository
This will be a highly advanced example data generation, as it will have to match on the positions in the example dbsnp databases. First step is to create a file of common snps on GRCh38 from a set of sumstats also intended to be used as example data. This will be the link between the two datasets making it possible to run the whole workflow using only this reduced data. 

```
sslib="${HOME}/IBP_pipeline_cleansumstats_alpha/cleansumstats_v1.0.0-alpha/sumstat_library"
sspdfs="${HOME}/IBP_pipeline_cleansumstats_alpha/cleansumstats_v1.0.0-alpha/sumstat_pdfs"

# create sumstat workdir
mkdir -p sumstat_generation
mkdir -p sumstat_generation/var_selection

# Make variant selection file from sumstats
# We are using alpha library, therefore converting each sumstat to GRCh38
for id in {1..5}; do
  # Save only GRCh38 positions and sort them
  LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" <(echo -e "0\tCHR_GRCh38\tPOS_GRCh38\n"; zcat ${sslib}/sumstat_${id}/sumstat_${id}_cleaned_GRCh38.gz) <(zcat ${sslib}/sumstat_${id}/sumstat_${id}_cleaned_GRCh37.gz) | awk -vFS="\t" 'NR>1{print $2":"$3}' | LC_ALL=C sort -k 1,1 > sumstat_generation/var_selection/sumstat_${id}_GRCh38_chrpos_sorted
done

# join the files
LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" sumstat_generation/var_selection/sumstat_1_GRCh38_chrpos_sorted sumstat_generation/var_selection/sumstat_2_GRCh38_chrpos_sorted | \
LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" - sumstat_generation/var_selection/sumstat_3_GRCh38_chrpos_sorted | \
LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" - sumstat_generation/var_selection/sumstat_4_GRCh38_chrpos_sorted | \
LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" - sumstat_generation/var_selection/sumstat_5_GRCh38_chrpos_sorted > \
sumstat_generation/var_selection/sumstat_1-5_GRCh38_chrpos_sorted_union

# Create a ready subset using the index
for id in {1..5}; do
  mkdir -p sumstat_generation/sumstat_${id}
  LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" <(echo -e "0\tCHR_GRCh38\tPOS_GRCh38\n"; zcat ${sslib}/sumstat_${id}/sumstat_${id}_cleaned_GRCh38.gz) <(zcat ${sslib}/sumstat_${id}/sumstat_${id}_cleaned_GRCh37.gz) | awk -vFS="\t" 'NR>1{print $2":"$3, $1}' | LC_ALL=C sort -k 1,1 | LC_ALL=C join -1 1 -2 1 - sumstat_generation/var_selection/sumstat_1-5_GRCh38_chrpos_sorted_union | awk '{print $2}' | LC_ALL=C sort -k 1,1 > sumstat_generation/sumstat_${id}/sumstat_${id}_union_subset_index_sorted
  LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" <(zcat ${sslib}/sumstat_${id}/sumstat_${id}_raw_formatted_rowindexed.gz) sumstat_generation/sumstat_${id}/sumstat_${id}_union_subset_index_sorted | cut -d$'\t' --complement -f1 > sumstat_generation/sumstat_${id}/sumstat_${id}_union_subset
  rm sumstat_generation/sumstat_${id}/sumstat_${id}_union_subset_index_sorted
done

# Prepare remaining sumstat files
for id in {1..5}; do

 # Give better name and compress
 cp sumstat_generation/sumstat_${id}/sumstat_${id}_union_subset sumstat_generation/sumstat_${id}/sumstat_${id}_raw
 gzip -9 -c sumstat_generation/sumstat_${id}/sumstat_${id}_raw > sumstat_generation/sumstat_${id}/sumstat_${id}_raw.gz
 rm sumstat_generation/sumstat_${id}/sumstat_${id}_raw
 rm sumstat_generation/sumstat_${id}/sumstat_${id}_union_subset


 # alpha meta data
 cp ${sslib}/sumstat_${id}/sumstat_${id}_raw_meta.txt sumstat_generation/sumstat_${id}/sumstat_${id}_raw_meta_v_1.0.0-alpha.txt

 # README
 if [ -f "${sslib}/sumstat_${id}/sumstat_${id}_raw_README.txt" ]; then
   cp ${sslib}/sumstat_${id}/sumstat_${id}_raw_README.txt sumstat_generation/sumstat_${id}/sumstat_${id}_raw_README.txt
 fi

 # PDFs, and because of broken symlinks we have to use pattern matching
 pmid="$(ls ${sslib}/sumstat_${id}/sumstat_*_pmid*pdf | awk '{gsub(/.*sumstat_.*pmid_/,"");gsub(/.pdf/,"")}1')"
 #cp ${sspdfs}/pmid_${pmid}.pdf sumstat_generation/sumstat_${id}/sumstat_${id}_pmid_${pmid}_pdf
 #cp -r ${sspdfs}/pmid_${pmid}_supp sumstat_generation/sumstat_${id}/sumstat_${id}_pmid_${pmid}_supp

 # Use dummy pdfs in case needed as example data in repo
 echo "placeholder file as a pdf is too large, and wouldnt be used by the pipelinen other than being copied" > sumstat_generation/sumstat_${id}/sumstat_${id}_pmid_${pmid}_pdf

 # For each file in folder replace with dummy file
 for file in $(ls -1 ${sspdfs}/pmid_${pmid}_supp); do
   mkdir -p sumstat_generation/sumstat_${id}/sumstat_${id}_pmid_${pmid}_supp
   echo "placeholder file as a pdf is too large, and wouldnt be used by the pipeline other than being copied" > sumstat_generation/sumstat_${id}/sumstat_${id}_pmid_${pmid}_supp/${file}
 done
done

```

The metafiles just created will be of the old alpha format. To update them to the new format we need to run the converter script.

```
# Convert each sumstat alpha meta file to new format
for id in {1..5}; do
  ./scripts/singularity-run.sh /cleansumstats/bin/metadata_legacy_to_yaml.py sumstat_generation/sumstat_${id}/sumstat_${id}_raw_meta_v_1.0.0-alpha.txt > tmp/fake-home/sumstat_generation/sumstat_${id}/sumstat_${id}_raw_meta.txt
done

# Move all sumstat data into the example data folder
mv tmp/fake-home/sumstat_generation/sumstat_* tests/example_data/

```

### Shrink the dbsnp vcf source
The real life example data is created with start from the dbsnp vcf file, by making it small enough to run e2e tests and for quick-start purposes, or simply for easy debugging.

```
# Download the dbsnp data ( or reuse an existing copy )
wget ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf

# Prepare header by capturing all lines with #
zcat All_20180418.vcf.gz | head -n10000 | grep "#" > All_20180418_example_data.vcf

# decompress and add a column with sorted chrpos information
pigz --decompress --stdout --processes 2 All_20180418.vcf.gz | grep -v "#" | awk -vOFS="\t" 'NR>1{print $1":"$2, $0}' > All_20180418.vcf.chrpos


# The multi-thread sort takes around 30 min with the resources specified below
srun --mem=200g --ntasks 1 --cpus-per-task 10 --time=4:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
LC_ALL=C sort -k 1,1 --parallel 8 All_20180418.vcf.chrpos > All_20180418.vcf.chrpos_sorted

# Join to the union of variants from the selected set of sumstats (remove chrpos index)
LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" ../../sumstat_generation/var_selection/sumstat_1-5_GRCh38_chrpos_sorted_union All_20180418.vcf.chrpos_sorted | cut -d$'\t' --complement -f1 > All_20180418.vcf.chrpos_sorted_joined

# Make a random selection to capture variants from all across the genome, generate random seed source file
seedval=1337
openssl enc -aes-256-ctr -pass pass:"${seedval}" -nosalt </dev/zero 2>/dev/null | head -10000 > random_seed_file_source

# Make the random selection of 1000 variants using seed source file
zcat All_20180418.vcf.gz | head -n1000 | grep "#" > All_20180418_example_data.vcf
sort -R --random-source=random_seed_file_source --parallel=2 --buffer-size=10G All_20180418.vcf.chrpos_sorted_joined | head -n 1000 >> All_20180418_example_data.vcf

# gzip the result with best compression (=9)
gzip -9 All_20180418_example_data.vcf

# clean all intermediate files (save the random seed for future reference)
rm All_20180418.vcf.chrpos
rm All_20180418.vcf.chrpos_sorted
rm All_20180418.vcf.chrpos_sorted_joined

# Place the example data in the 'tests/example_data/dbsnp/' folder (the automatic tests will look for it there)
mv "All_20180418_example_data.vcf.gz" tests/example_data/dbsnp/

```

### Create the cleansumstats version of the dbsnp reference (including liftover etc)
This is the same script as used for the full size dbsnp vcf data

```
# Generate dbsnp cleansumstat reference
./scripts/singularity-run.sh nextflow run /cleansumstats \
  --generateDbSNPreference \
  --input /cleansumstats/tests/example_data/dbsnp/All_20180418_example_data.vcf.gz \
  --dev \
  --outdir ./out

# Move the generated reference files into 'tests/example_data/dbsnp/generated_reference/'
mkdir -p tests/example_data/dbsnp/generated_reference
results="tmp/fake-home/sumstat_reference/dbsnp151/"
mv ${results}/* tests/example_data/dbsnp/generated_reference/

```

### Shrink the 1kg reference source
Download 1000 genomes project data.

```
# Download readme describing the new mapping directly to GRCh38
wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/20190312_biallelic_SNV_and_INDEL_README.txt

# Then download the dataset from this website portal
wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz
wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz.tbi
```

Use same set of variants as in dbsnp example reference. This will automatically happen when using the built in workflow 'generate1KgAfSNPreference'. Provided that we supply the dbsnp example reference and not the full size dbsnp reference. Although, to be useful to easily test the actual 1kg allele frequency reference generation, it is good to subset the data to only the variants already in the sumstat and dbsnp example data. 

```
mkdir -p tmp_1kg

# Decompress and add a column with sorted chrpos information
pigz --decompress --stdout --processes 2 ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz | grep -v "#" | awk -vOFS="\t" 'NR>1{print $1":"$2, $0}' > tmp_1kg/1kg_example_data.vcf.chrpos

# The multi-thread sort takes around 1 min with the resources specified below
srun --mem=200g --ntasks 1 --cpus-per-task 10 --time=4:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
LC_ALL=C sort -k 1,1 --parallel 8 tmp_1kg/1kg_example_data.vcf.chrpos > tmp_1kg/1kg_example_data.vcf.chrpos_sorted

# Prepare header by capturing all lines with #
zcat ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz | head -n10000 | grep "#" > tmp_1kg/1kg_example_data.vcf.chrpos_sorted_joined

# Join to the union of variants from the selected set of sumstats (remove chrpos index)
LC_ALL=C join -1 1 -2 1 -t "$(printf '\t')" ../../sumstat_generation/var_selection/sumstat_1-5_GRCh38_chrpos_sorted_union tmp_1kg/1kg_example_data.vcf.chrpos_sorted | cut -d$'\t' --complement -f1 >> tmp_1kg/1kg_example_data.vcf.chrpos_sorted_joined

# gzip
gzip -9 -c tmp_1kg/1kg_example_data.vcf.chrpos_sorted_joined > tmp_1kg/1kg_example_data.vcf.chrpos_sorted_joined.gz

# move to example data folder
#mkdir -p tests/example_data/1kgp
cp tmp/fake-home/source_data/1kgp/tmp_1kg/1kg_example_data.vcf.chrpos_sorted_joined.gz tests/example_data/1kgp/1kg_example_data.vcf.gz

```

```
# Generate dbsnp cleansumstat reference
./scripts/singularity-run.sh nextflow run /cleansumstats \
  --generate1KgAfSNPreference \
  --input /cleansumstats/tests/example_data/1kgp/1kg_example_data.vcf.gz \
  --libdirdbsnp /cleansumstats/tests/example_data/dbsnp/generated_reference \
  --dev 
  --outdir ./out

# Move the generated reference files into 'tests/example_data/dbsnp/generated_reference/'
results="tmp/fake-home/sumstat_reference/dbsnp151/"

```



## Useful information

- All chain files for the liftover/crossover operations have been embedded in the image. See the dockerfile for path to the web source.
- `sort` threats a file as small if comming from a pipe, which cancel parallelization.
- `sort` doesn't make use of more than 8 cpus according to its documentation.
- `sort` `--buffer-size=20G` is useful to get better control of memory allocation.

# Developer instructions
Here we collect developer specific documentation, which never should be of interest of a user

## Creating the ibp-pipeline-lib .jar file
Build the ibp-pipeline-lib-x.x.x.jar file accroding to instructions at: https://github.com/BioPsyk/ibp-pipeline-lib, Then place it inside the docker/ directory in the cleansumstats repository to be accessible by the docker build script. To facilitate development and because of the small size of the image, we have decided to store the correct version for this repo in the docker/ directory. If in the future this file becomes too large we might exclude it from the repo.

## Creating "real-life" example data

### Shrink the dbsnp vcf source
The real life example data is created with start from the dbsnp vcf file, by making it small enough to run e2e tests and for quick-start purposes, or simply for easy debugging.

```
# Download the dbsnp data ( or reuse an existing copy )
wget ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf

# Prepare header by capturing all lines with #
zcat All_20180418.vcf.gz | head -n10000 | grep "#" > All_20180418_example_data.vcf

# Make a random selection to captura all chromosomes and more disperse regions
seedval=1337
openssl enc -aes-256-ctr -pass pass:"$seedval" -nosalt </dev/zero 2>/dev/null | head -10000 > random_seed_file_source
# To save a lot of time, split the data to process in parallel.
pigz --decompress --stdout --processes 2 All_20180418.vcf.gz | grep -v "#" > All_20180418.vcf
mkdir -p chunks
split -d -n l/20 All_20180418.vcf chunks/chunk_

# start an interactive node with many cores, and then execute the job
srun --mem=500g --ntasks 20 --cpus-per-task 3 --time=4:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
for chunk in chunks/chunk_*; do \
 ( \
 echo "$chunk starting ..."; \
  sort -R --random-source=random_seed_file_source --parallel=3 --buffer-size=20G ${chunk} | head -n 100 > "${chunk}_rset"
 echo "$chunk done ..."; \
 ) & \
done

# merge the result into one file
zcat All_20180418.vcf.gz | head -n1000 | grep "#" > All_20180418_example_data.vcf
cat chunks/*_rset >> All_20180418_example_data.vcf
gzip -9 All_20180418_example_data.vcf

# clean all intermediate files (save the random seed for future reference)
rm All_20180418.vcf
rm chunks/*
rmdir chunks

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
  --outdir ./out

# Move the generated reference files into 'tests/example_data/dbsnp/generated_reference/'
results="tmp/fake-home/sumstat_reference/dbsnp151/"
mv ${results}/All_20180418_GRCh35_GRCh38.sorted.bed tests/example_data/dbsnp/generated_reference/
mv ${results}/All_20180418_GRCh36_GRCh38.sorted.bed tests/example_data/dbsnp/generated_reference/
mv ${results}/All_20180418_GRCh37_GRCh38.sorted.bed tests/example_data/dbsnp/generated_reference/
mv ${results}/All_20180418_GRCh38_GRCh37.sorted.bed tests/example_data/dbsnp/generated_reference/
mv ${results}/All_20180418_RSID_GRCh38.sorted.bed tests/example_data/dbsnp/generated_reference/
mv ${results}/All_20180418_GRCh38.sorted.bed tests/example_data/dbsnp/generated_reference/

```

### Shrink the 1kg reference source (use same set of variants as in dbsnp example reference)




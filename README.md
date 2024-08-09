# cleansumstats

**Convert GWAS sumstat files into a common format with a common reference for positions, rsids and effect alleles**

[![DOI](https://zenodo.org/badge/231274941.svg)](https://zenodo.org/badge/latestdoi/231274941)


## Introduction
The cleansumstats pipeline takes a typical genomic sumstat file as input(normally the output from a GWAS), together with specifiers for chr, pos and available stats.


## Quick Start
To run a quick test using provided example and test data. Use either singularity or docker depending on what is available on your system. Note that Singularity has been renamed Apptainer.

```bash
# Make sure git and either singularity or docker are installed
git --version
singularity --version
docker --version

# clone and enter the cleansumstats github project
git clone https://github.com/BioPsyk/cleansumstats.git
cd cleansumstats
```

### Singularity
using singularity (use path to image)
```bash
## pull singularity image returning the image as a file)
mkdir -p sif
singularity pull sif/ibp-cleansumstats-base_version-1.2.2.sif docker://biopsyk/ibp-cleansumstats:1.2.2

# clean a sumstat using shrinked example data for dbsnp and 1kgp (-e flag)
./cleansumstats.sh \
  -j ibp-cleansumstats-base_version-1.2.2.sif \
  -i tests/example_data/sumstat_1/sumstat_1_raw_meta.txt \
  -o out_example \
  -e 1
```

### Docker
using docker image (use the tag: dockerhub_biopsyk)
```bash
## pull docker image
docker pull biopsyk/ibp-cleansumstats:1.2.2
## using docker (using flag -j)
./cleansumstats.sh \
  -j dockerhub_biopsyk \
  -i tests/example_data/sumstat_1/sumstat_1_raw_meta.txt \
  -o out_example \
  -e 1

```

## Add full size reference data
In the cleaning all positions are compared to a reference to confirm or add missing annotation.

### dbsnp reference
The preparation of the dbsnp reference only has to be done once, and can be reused for all sumstats that needs cleaning.

```bash
# i. Download the dbsnp reference and supplemental files: size 25GB 
mkdir -p dbsnp
wget -P dbsnp https://ftp.ncbi.nlm.nih.gov/snp/archive/b156/VCF/CHECKSUMS
wget -P dbsnp https://ftp.ncbi.nlm.nih.gov/snp/archive/b156/VCF/GCF_000001405.40.gz.md5
wget -P dbsnp https://ftp.ncbi.nlm.nih.gov/snp/archive/b156/VCF/GCF_000001405.40.gz.tbi
wget -P dbsnp https://ftp.ncbi.nlm.nih.gov/snp/archive/b156/VCF/GCF_000001405.40.gz

# ii. If you are on a HPC Start your interactive session (below SLURM settings took about 5h to run)
srun --mem=400g --ntasks 1 --cpus-per-task 60 --time=10:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
./cleansumstats.sh \
  prepare-dbsnp \
  -i dbsnp/GCF_000001405.40.gz \
  -o out_dbsnp
```

### 1000 genomes project reference
```bash
# i. Download
mkdir -p 1kgp
wget -P 1kgp http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz
wget -P 1kgp http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz.tbi

# ii. If you are on a HPC Start your interactive session (below SLURM settings took about 5min to run)
srun --mem=80g --ntasks 1 --cpus-per-task 5 --time=1:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
./cleansumstats.sh \
  prepare-1kgp \
  -i 1kgp/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz \
  -d out_dbsnp \
  -o out_1kgp
```

## Prepare meta data files
After the reference data (dbsnp and 1000 genomes) has been created it is time to prepare the input for the actual cleaning. This file is called the meta file, and contains paths to other important files, such as the actual sumstats, README, article pdf, etc,. for which all need to be in the same folder as their corresponding metafile. This file has to be filled in manually, see `tests/example_data/sumstat_1/sumstat_1_raw_meta.txt` for an example of how it looks like. 

You can also use this [webinterface](https://biopsyk.github.io/metadata) to generate a metadatafile. Again, remember that all files referred to by the metadatafile have to be in the same directory as the metafile when you run cleansumstats. Check `tests/example_data` and sumstats 1-5 for an example of how you can structure your input folders.

There is no support for relative links in the metadata file, which means all files have to be in the same folder. However, you can provide paths to associated files `-p path/to/folder1,path/to/folder2`

## Run a fully operational cleaning pipeline 
This will take longer time compared to the quick-start run as we now use the full >600 million rows dbsnp reference to map our variants to.

When you have prepared your meta data files, then replace `-i` example data with your own data.

```
# i. If you are on a HPC Start your interactive session (below SLURM settings took about 10min to run)
srun --mem=40g --ntasks 1 --cpus-per-task 6 --time=1:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
./cleansumstats.sh \
  -i tests/example_data/sumstat_1/sumstat_1_raw_meta.txt \
  -d out_dbsnp \
  -k out_1kgp \
  -o out_clean

# For additional flags, see:
./cleansumstats.sh -h

```


## More documentation
- See [Output and how to interpret the results](docs/output.md) for the output structure and how to interpret the results.
- See [Post-processing](docs/post-processing.md) for how to further process the output
- And [more](docs/README.md) 


## Credits

cleansumstats was originally written by Jesper R. Gådin

# cleansumstats

**Convert GWAS sumstat files into a common format with a common reference for positions, rsids and effect alleles.**.

[![Build Status](https://travis-ci.com/nf-core/cleansumstats.svg?branch=master)](https://travis-ci.com/nf-core/cleansumstats)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)

## Introduction
The clean sumstats pipeline takes a genomic sumstat file as input(normally output from  GWAS), together with specifiers for chr, pos and available stats. 

Briefly, the pipeline first detects genome build, then map to a dbsnp build to kepp only entries with rsids and ref/alt allele information. Secondly, using information of which allele is A1, the direction of the statistic is assesed. Lastly, an output file is assembled, which then can be directly compared to other similar studies. 

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start
To run a quick test using provided example and test data

```bash
# i. Make sure singularity is installed, see [singularity installation](docs/singularity-installation.md) 

# ii. Download our container image containing all software and code needed

# iii. Run the singularity image using the provided test data
./scripts/singularity-run.sh /cleansumstats/tests/run-tests.sh

# iv. Run the singularity image using a subset of real worl example data (example data is to be generated)
#./scripts/singularity-run.sh --input /cleansumstats/tests/example_data

```

## Use your own data

Prepare a complete dbsnp reference. This takes some time, but only has to be done once, and can be reused for all sumstats that needs cleaning. 

```bash
# i. Download the dbsnp reference: size 15GB (and the readme, etc for future reference)
mkdir -p source_data
wget -P source_data ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/README.txt
wget -P source_data ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz.md5
wget -P source_data ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz.tbi
wget -P source_data ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz

# ii. If you are on a HPC Start your interactive session (cpus =< 40) and simply run the following
srun --mem=80g --ntasks 20 --cpus-per-task 1 --time=10:00:00 --pty /bin/bash
./scripts/singularity-run.sh nextflow run /cleansumstats \
  --generateDbSNPreference \
  --input source_data/All_20180418_example_data.vcf.gz \
  --outdir ./out

 ## --input source_data/All_20180418.vcf.gz \

```

ii. Prepare meta data for each sumstat file to process
```bash
#this takes time, but only has to be done one time.

```

iii. Start running the cleaning of your own sumstat files!

```bash
#point to metadatafile

```

## Using images

### Pre-requisites

Docker and singularity has to be installed to create an image executable at a HPC
- docker-install-instructions(todo)
- [singularity installation](docs/singularity-installation.md) 

### build images

We have decided to build a docker image first to facilitate how it uses layers to speed up development. From that docker image, it is simple and easy to create a singularity image when deploying the pipeline. The created singulariy image goes to the 'tmp/' folder.

```bash
# Build docker image (tied to your system)
./scripts/docker-build.sh

# Build singularity image (movable to other systems)
./scripts/singularity-build.sh
```

### Use docker image

Run tests using the docker image. We have implemented several tests to ensure that the pipeline is doing what we expect. They should all return ok.

```bash
# using docker
./scripts/docker-run.sh /cleansumstats/tests/run-tests.sh

# using singularity
./scripts/singularity-run.sh /cleansumstats/tests/run-tests.sh
```

## More documentation
- See [usage docs](docs/usage.md) for all of the available options when running the pipeline.
- See [Output and how to interpret the results](docs/output.md) for the output structure and how to interpret the results.
- See [Developer instructions](docs/developers.md) only for developers

## Credits

cleansumstats was originally written by Jesper R. Gådin


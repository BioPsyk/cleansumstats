# cleansumstats

**Convert GWAS sumstat files into a common format with a common reference for positions, rsids and effect alleles.**.

[![Build Status](https://travis-ci.com/nf-core/cleansumstats.svg?branch=master)](https://travis-ci.com/nf-core/cleansumstats)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)

## Introduction

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

i. Make sure singularity is installed, see [singularity installation](docs/singularity-installation.md) 

ii. Download our container image containing all software and code needed
```bash
#code to download from the IBP image repository

```

iii. Run the singularity image using the provided test data

```bash
nextflow run nf-core/cleansumstats -profile test,<docker/singularity/conda>
```

## Use your own data

iv. Prepare reference data
```bash
#this takes time, but only has to be done one time.

```

v. Prepare meta data for each sumstat file to process
```bash
#this takes time, but only has to be done one time.

```

vi. Start running the cleaning of your own sumstat files!

```bash
#point to metadatafile

```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.
See [Output and how to interpret the results](docs/output.md) for the output structure and how to interpret the results.

## Documentation

The clean sumstats pipeline takes a genomic sumstat file as input(normally output from  GWAS), together with specifiers for chr, pos and available stats. 

Briefly, the pipeline first detects genome build, then map to a dbsnp build to kepp only entries with rsids and ref/alt allele information. Secondly, using information of which allele is A1, the direction of the statistic is assesed. Lastly, an output file is assembled, which then can be directly compared to other similar studies. 

## Credits

cleansumstats was originally written by Jesper R. Gådin


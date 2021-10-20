# cleansumstats

**Convert GWAS sumstat files into a common format with a common reference for positions, rsids and effect alleles.**.

[![Build Status](https://travis-ci.com/nf-core/cleansumstats.svg?branch=master)](https://travis-ci.com/nf-core/cleansumstats)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)

## Introduction
The cleansumstats pipeline takes a typical genomic sumstat file as input(normally the output from a GWAS), together with specifiers for chr, pos and available stats.

### DbSNP and allele flipping
Briefly, the pipeline first detects the genome build, then map all variants to a dbsnp build to keep only positions with rsids and ref/alt allele information. After mapping to dbsnp the information is used to flip all allele effects in the direction of the ref allele. There are also other filters applied, which remove variants that are:
- palindromes
- not in the set of GCTA
- indel
- homozygous
- not expected A2 (in respect to dbsnp)
- not possible pair (in respect to dbsnp)

### Stat inference
We are using the available statistics to infer missing statistics, see [repo](https://github.com/pappewaio/r-stats-c-streamer) for the core tool doing that. All statistics are flipped in accordance to the ref allele. 

### Output
The last step of the worlflow is creating an output folder, which always has the same structure and names for each sumstat that is being processed.

### Engine
The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker and singularity containers making installation trivial and results highly reproducible.

## Quick Start
To run a quick test using provided example and test data

```bash
# i. Make sure singularity is installed, see [singularity installation](docs/singularity-installation.md)
singularity --version

# ii. Download our container image, move it to a folder called tmp within the repo (<1GB)
singularity pull ibp-cleansumstats-base_version-1.0.0.simg docker://biopsyk/ibp-cleansumstats:1.0.0
mkdir -p tmp
mv ibp-cleansumstats-base_version-1.0.0.simg tmp/

# iii. Run the singularity image using example data
./scripts/singularity-run.sh nextflow run /cleansumstats \
  --input /cleansumstats/tests/example_data/sumstat_1/sumstat_1_raw_meta.txt \
  --outdir ./out_example

#iv. Run the same thing using a convenience wrapper that correctly mounts folders outside of tmp/
mkdir output
./cleansumstats.sh \
  -i tests/example_data/sumstat_1/sumstat_1_raw_meta.txt \
  -o output \
  -t

```

- The results from iii. can be found in ./tmp/out_example
- The results from iv. can be found in ./output

## Add full size reference data
In the cleaning all positions are compared to a reference to confirm or add missing annotation.

### dbsnp reference
The preparation of the dbsnp reference only has to be done once, and can be reused for all sumstats that needs cleaning.

```bash
# i. Download the dbsnp reference: size 15GB (and the readme, etc for future reference)
mkdir -p source_data/dbsnp
wget -P source_data/dbsnp ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/README.txt
wget -P source_data/dbsnp ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz.md5
wget -P source_data/dbsnp ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz.tbi
wget -P source_data/dbsnp ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz

# ii. If you are on a HPC Start your interactive session (below SLURM settings took about 5h to run)
srun --mem=400g --ntasks 1 --cpus-per-task 60 --time=10:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
./scripts/singularity-run.sh nextflow run /cleansumstats \
  --generateDbSNPreference \
  --input ./source_data/dbsnp/All_20180418.vcf.gz \
  --outdir ./out_dbsnp \
  --libdirdbsnp ./out_dbsnp
```

### 1000 genomes project reference
```bash
# i. Download
mkdir -p source_data/1kgp
wget -P source_data/1kgp http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz
wget -P source_data/1kgp http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz.tbi

# ii. If you are on a HPC Start your interactive session (below SLURM settings took about 5min to run)
srun --mem=80g --ntasks 1 --cpus-per-task 5 --time=1:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
./scripts/singularity-run.sh nextflow run /cleansumstats \
  --generate1KgAfSNPreference \
  --input ./source_data/1kgp/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz \
  --outdir ./out_1kgp \
  --kg1000AFGRCh38 ./out_1kgp
```

## Prepare meta data files
After the reference data paths have been set in the nextflow.config file, the pipeline can be run with only one argument, pointing to only one file. This file is called the meta file, and contains paths to other important files, such as the actual sumstats, README, article pdf, etc,. for which all need to be in the same folder as their corresponding metafile. This file has to be filled in manually, see tests/example_data/sumstat_1/sumstat_1_raw_meta.txt for an example of how it looks like. 

## Run a fully operational cleaning pipeline (Replace example data with your own data to clean)
This will take longer time compared to the quick-start run as we now use the full >600 million rows dbsnp reference to map our variants to. The '--libdirdbsnp' and '--kg1000AFGRCh38' default is a smaller set of example data used for the quick start in the beginning of the README)

```
# i. If you are on a HPC Start your interactive session (below SLURM settings took about 10min to run)
srun --mem=40g --ntasks 1 --cpus-per-task 6 --time=1:00:00 --account ibp_pipeline_cleansumstats --pty /bin/bash
./scripts/singularity-run.sh nextflow run /cleansumstats \
  --input /cleansumstats/tests/example_data/sumstat_1/sumstat_1_raw_meta.txt \
  --outdir ./out_clean \
  --libdirdbsnp ./out_dbsnp \
  --kg1000AFGRCh38 ./out_1kgp
```

```
# ii. Same as above, but instead using the convenience wrapper, and instead using ./out_dbsnp and ./out_1kgp as default reference locations. To quickly access the small reference sets, it is possible to use the -t flag, intended only for testing purposes.

mkdir -p output
./cleansumstats.sh \
  -i ./tests/example_data/sumstat_1/sumstat_1_raw_meta.txt \
  -o ./output

# For additional flags, see:
./cleansumstats.sh -h
##Example usage, specify output and the test flag:
## ./cleansumstats.sh -o output -t
##
##Simple Usage:
## ./cleansumstats.sh -i <file> -o <dir>
##
##Advanced Usage:
## ./cleansumstats.sh -i <file> -o <dir> -d <dir> -k <dir>
##
##options:
##-h		 Display help message for cleansumstats
##-i <file> 	 path to meta file
##-o <dir> 	 path to output directory
##-d <dir> 	 path to dbsnp processed reference
##-k <dir> 	 path to 1000 genomes processed reference
##-t  	 	 test the example version of dbsnp and 1000 genomes references
##
##
##NOTE: For 'simple usage' it requires dbsnp and 1000G project references to be set up and linked to in the config file.

```


## More documentation
- See [usage docs](docs/usage.md) for all of the available options when running the pipeline.
- See [Output and how to interpret the results](docs/output.md) for the output structure and how to interpret the results.
- See [Developer instructions](docs/developers.md) only for developers

## Credits

cleansumstats was originally written by Jesper R. Gådin

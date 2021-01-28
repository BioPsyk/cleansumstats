# nf-core/cleansumstats: Usage

## Table of contents
<!-- TOC START min:1 max:3 link:true asterisk:false update:true -->
- [nf-core/cleansumstats: Usage](#nf-corecleansumstats-usage)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Running the pipeline](#running-the-pipeline)
    - [Reproducibility](#reproducibility)
  - [Main arguments](#main-arguments)
    - [`--input`](#--input)
    - [`--outdir`](#--outdir)
  - [dbSNP reference](#dbsnp-reference)
    - [`--generateDbSNPreference`](#--generatedbsnpreference)
    - [`--libdirdbsnp`](#--libdirdbsnp)
  - [Allele frequency reference](#allele-frequency-reference)
    - [`--generate1KgAfSNPreference`](#--generate1kgafsnpreference)
    - [`--libdir1kaf`](#--libdir1kaf)
    - [`--kg1000AFGRCh38`](#--kg1000afgrch38)
  - [Chain files](#chain-files)
  - [Filters](#filters)
    - [`--beforeLiftoverFilter`](#--beforeliftoverfilter)
    - [`--afterLiftoverFilter`](#--afterliftoverfilter)
    - [`--afterAlleleCorrectionFilter`](#--afterallelecorrectionfilter)
  - [Job management and resources](#job-management-and-resources)
    - [Automatic resubmission](#automatic-resubmission)
    - [`--email`](#--email)
    - [`--email_on_fail`](#--email_on_fail)
    - [`-name`](#-name)
    - [`-resume`](#-resume)
    - [`--max_memory`](#--max_memory)
    - [`--max_time`](#--max_time)
    - [`--max_cpus`](#--max_cpus)
    - [`--plaintext_email`](#--plaintext_email)
    - [`--monochrome_logs`](#--monochrome_logs)
    - [`--dev`](#--dev)
<!-- TOC END -->

## Introduction
Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## Running the pipeline
The typical command for running the pipeline is as follows:

```bash
nextflow run cleansumstats --input metadatafile --outdir results
```

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Reproducibility
The pipeline version is indicated in the file name of the downloaded image. There are two ways of accessing version information of the included software.

1. Studying the software version file from the output after running the pipeline on your data.
2. Enter the image and test each included softwares version:
```
#Code to do so

```

## Main arguments

### `--input`
Use this to specify the location of your metadata file. For example:

```bash
#single file
--input 'path/to/data/metadatafile1'

#multiple files using asterix(*)
--input 'path/to/data/metadatafile*'
```

### `--outdir`
The output directory where the results will be saved.

Please note the following requirements for multi-file input:

1. The path must be enclosed in quotes
2. The path must have at least one `*` wildcard character

## dbSNP reference
The pipeline requires a reference like dbsnp to map rsid and positions to. In cleansumstats the dbsnp information on which allele is the ref allele is also used to flipe the effect allele, so that the ref allele always is the effect allele. Additionally, we require a prepared dbsnp reference that contains build information.
### `--generateDbSNPreference`
To produce this reference, download the dbsnp database, and run the following script.

```bash
# Download dbsnp database
# wget ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.*

--generateDbSNPreference --input path/to/All_20180418.vcf.gz
```

### `--libdirdbsnp`
The reformatted database files will be stored in the default directory, specified in the nextflow.config script. But can be specified on the command line using this parameter.

```bash
--libdirdbsnp /path/to/dbSNPreferenceFolder
```
Each individuals database file can be set using these flags
```bash
--dbsnp_38 /path/to/file
--dbsnp_38_37 /path/to/file
--dbsnp_37_38 /path/to/file
--dbsnp_36_38 /path/to/file
--dbsnp_35_38 /path/to/file
--dbsnp_RSID_38 /path/to/file

```


## Allele frequency reference
For allele frequency we use 1000 genomes data for the main groups AFR, EAS, EUR, AMR and SAS. Similar to dbsnp, this data also needs to be preprocessed before we use it in the pipeline. It can be downloaded from 1000 genomes ftp portal.

```bash
# download README describing the new mapping directly to GRCh38
wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/20190312_biallelic_SNV_and_INDEL_README.txt

# Download the data (.gz and .gz.tbi)
wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz*

```

### `--generate1KgAfSNPreference`

```bash
--generate1KgAfSNPreference --input path/to/vcffile.gz
```

### `--libdir1kaf`
To set output directory of the allele frequency reference to use. When running pipeline the same parameter is used to indicate where the allele frequency reference directory is located.

```bash
--libdir1kaf path/to/dir/
```

### `--kg1000AFGRCh38`
To set output path of the allele frequency reference file to use. When running pipeline the same parameter is used to set the allele frequency reference file.

```bash
--kg1000AFGRCh38 path/to/file/
```

## Chain files
Chain files used in the preparation of the liftover reference

```bash
--hg38ToHg19chain = path/to/file
--hg19ToHg18chain = path/to/file
--hg19ToHg17chain = path/to/file
```

## Filters
Commma separated arguments, which filter the data in different ways

### `--beforeLiftoverFilter`
By default this filters on duplicated keys, which means either the chr:pos, or rsid key used to match dbsnp entries(aka the liftover step).

```bash
--beforeLiftoverFilter = "duplicated_keys"
```

### `--afterLiftoverFilter`
By default this filters lines which are duplicated either by chr:pos and ref:alt, or rsid

```bash
--afterLiftoverFilter = "duplicated_chrpos_refalt_in_GRCh38,multiple_rsids_in_dbsnp"
```

### `--afterAlleleCorrectionFilter`
This filter has no set default, and is therefore set to "".
```bash
--afterAlleleCorrectionFilter = ""
```


## Job management and resources
### Automatic resubmission
Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped. (Feature not implemented yet)

### `--email`
Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.

### `--email_on_fail`
This works exactly as with `--email`, except emails are only sent if the workflow is not successful.

### `-name`
Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

### `-resume`
Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

### `--max_memory`
Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'`

### `--max_time`
Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### `--max_cpus`
Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`

### `--plaintext_email`
Set to receive plain-text e-mails instead of HTML formatted.

### `--monochrome_logs`
Set to disable colourful command line output and live life in monochrome.

### `--dev`
Use the dev flag to indicate that you want all intermediate files in the output
```bash
--dev
```

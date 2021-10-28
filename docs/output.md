# cleansumstats: Output

Details about the output should be available here at some point

## Overview

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
The last step of the workflow is creating an output folder, which always has the same structure and names for each sumstat that is being processed.

### Engine
The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker and singularity containers making installation trivial and results highly reproducible.

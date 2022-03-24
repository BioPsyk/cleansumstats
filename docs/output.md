# cleansumstats: Output

Details about the output should be available here at some point

## modify output structure
By default everything is located in the folder specified by `cleansumstats.sh -o`, which internally will be managed as `params.outdir`. It is however possible to independently set the different output categories to their own location. In `nextflow.config`, see the section containing these lines:
```
  //output
  intermediates="${params.outdir}/intermediates"
  rawoutput="${params.outdir}/raw"
  details="${params.outdir}/details"
  pipeline_info="${params.outdir}/pipeline_info"
```

If you don't want the raw output, then use:
```
  rawoutput=false
```

## Overview

#### Prepare DbSNP
To make the lookup in dbsnp fast we need to convert it to our internal format.

The preparation of dbsnp to our internal format does some initial filtering:
- removes indels
- removes ambigous chromosomes, i.e., all chromosome names including _ in the name.
- removes all duplicates for each variant in the builds 35,36,37 and 38. Keeping one of the duplicates.

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

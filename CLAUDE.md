# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CleanSumstats is a Nextflow-based bioinformatics pipeline that standardizes GWAS summary statistics files by:
- Converting them to a common format
- Mapping variants to standard references (dbSNP, 1000 Genomes)
- Performing allele correction and liftover between genome builds
- Filtering duplicates and problematic variants

## Key Commands

### Running the Pipeline

```bash
# Standard cleaning run with full references
./cleansumstats.sh \
  -i path/to/metadata.yaml \
  -d path/to/dbsnp_reference \
  -k path/to/1kgp_reference \
  -o output_directory

# Quick test with example data (reduced references)
./cleansumstats.sh -e 1 -o out_test

# Using Docker
./cleansumstats.sh -j docker -i metadata.yaml -o output

# Using Singularity
./cleansumstats.sh -j sif/ibp-cleansumstats-base_version-1.3.0.sif -i metadata.yaml -o output
```

### Preparing Reference Data

```bash
# Prepare dbSNP reference (requires ~400GB RAM, ~5 hours)
./cleansumstats.sh prepare-dbsnp \
  -i dbsnp/GCF_000001405.40.gz \
  -o out_dbsnp

# Prepare 1000 Genomes reference (requires dbSNP reference)
./cleansumstats.sh prepare-1kgp \
  -i 1kgp/1000GENOMES-phase_3.vcf.gz \
  -d out_dbsnp \
  -o out_1kgp
```

### Running Tests

```bash
# Run all tests
./cleansumstats.sh test -j docker

# Run unit tests only
./cleansumstats.sh test -u -j docker

# Run end-to-end tests only
./cleansumstats.sh test -e -j docker

# Alternative: direct test script execution
tests/run-tests.sh        # Runs all tests
tests/run-unit-tests.sh    # Unit tests only
tests/run-e2e-tests.sh     # End-to-end tests only
```

## Architecture Overview

### Main Components

1. **Entry Points**
   - `cleansumstats.sh`: Main wrapper script for Docker/Singularity execution
   - `main.nf`: Nextflow pipeline entry point
   - `nextflow.config`: Pipeline configuration

2. **Nextflow Modules** (`modules/`)
   - `process/`: Individual pipeline processes (atomic operations)
   - `subworkflow/`: Grouped processes forming logical workflow units
   - Key workflows:
     - `main_init_checks`: Validates input and metadata
     - `map_to_dbsnp`: Maps variants to dbSNP reference
     - `allele_correction`: Corrects effect/reference alleles
     - `update_stats`: Calculates derived statistics
     - `organize_output`: Generates final cleaned files

3. **Shell Scripts** (`bin/`)
   - Individual data processing scripts called by Nextflow processes
   - Examples: `allele_correction.sh`, `map_to_dbsnp.sh`, `filter_stat_values_awk.sh`

4. **Reference Data**
   - dbSNP reference: Maps rsIDs and positions across genome builds
   - 1000 Genomes: Provides allele frequencies for validation

### Data Flow

1. **Input**: Metadata YAML file + raw sumstats file
2. **Validation**: Check columns, formats, required fields
3. **Mapping**: Match variants to dbSNP by CHR:POS or rsID
4. **Liftover**: Convert between genome builds if needed
5. **Allele Correction**: Ensure correct effect/reference alleles
6. **Filtering**: Remove duplicates and problematic variants
7. **Stats Update**: Calculate missing statistics (SE, P-values, etc.)
8. **Output**: Cleaned sumstats in GRCh37 and GRCh38

### Key File Formats

- **Metadata file**: YAML format specifying input file details, column mappings, and study information
- **Sumstats files**: Tab-separated files with variant-level statistics
- **Reference files**: Pre-processed dbSNP and 1KGP data in custom format

### Filtering Steps

- **Before liftover**: `duplicated_rsid_keys`
- **After allele correction**: Optional, configurable filters
- **Multiallelic handling**: Split or filter based on configuration

## Development Notes

- Pipeline uses Nextflow DSL2 syntax
- Containerization via Docker/Singularity is required (no local dependencies)
- Work directory contains intermediate files (use `-l` flag to preserve for debugging)
- Test data in `tests/example_data/` uses reduced reference files for faster testing
- Pipeline supports both command-line flags and `nextflow.config` parameters
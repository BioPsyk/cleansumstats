# Sumstat_6: Mapping-Only Workflow Example

This example dataset is designed to demonstrate the mapping-only workflow functionality in CleanSumstats.

## Dataset Description

The sumstat_6 dataset contains 25 variants with a mix of:

1. **Known dbSNP variants** (e.g., rs1000, rs12565286, rs3094315)
   - These should map successfully to dbSNP references
   - Will appear in GRCh37_mapped.gz and/or GRCh38_mapped.gz

2. **Novel/Unknown variants** (prefixed with NOVEL_, UNMAPPED_, etc.)
   - These won't be found in dbSNP
   - Will appear in unmapped.gz

3. **Different variant types**:
   - SNPs: Single nucleotide polymorphisms
   - INDELs: Insertions/deletions (e.g., INDEL_CHR2_500000)
   - Complex variants: Multi-base changes (e.g., COMPLEX_INDEL)
   - Multiallelic: Multiple alternate alleles (e.g., MULTIALLELIC_TEST)

4. **Various chromosomes**: Autosomal (1-20), X, and Y chromosomes

## File Contents

- `sumstat_6_raw_meta.yaml`: Metadata file describing the dataset
- `sumstat_6_raw.gz`: Compressed summary statistics data
- `sumstat_6_pmid_99999999.pdf`: Placeholder publication PDF

## Running the Example

### Quick Test (with minimal reference data):
```bash
./run_sumstat_6_mapping.sh --test
```

This uses the test reference data which only contains rs1000, so most variants will be unmapped.

### With Full References:
```bash
./cleansumstats.sh map-only \
  -i tests/example_data/sumstat_6/sumstat_6_raw_meta.yaml \
  -d path/to/dbsnp_reference \
  -k path/to/1kgp_reference \
  -o out_sumstat_6_mapping \
  --image docker
```

## Expected Output

The mapping-only workflow produces three main output files:

1. **GRCh38_mapped.gz**: Variants successfully mapped to GRCh38
2. **GRCh37_mapped.gz**: Variants successfully mapped to GRCh37  
3. **unmapped.gz**: Variants that couldn't be mapped to dbSNP

### With Test Reference
Since the test reference only contains rs1000:
- Only rs1000 will be in the mapped files
- All other variants will be in unmapped.gz

### With Full Reference
With complete dbSNP references:
- Known rsIDs will be properly mapped with their dbSNP information
- Novel variants (NOVEL_*, UNMAPPED_*, etc.) will remain unmapped
- Complex variants may or may not map depending on dbSNP coverage

## Examining Results

```bash
# Check mapped variants
zcat out_sumstat_6_mapping/GRCh38_mapped.gz | head

# Check unmapped variants  
zcat out_sumstat_6_mapping/unmapped.gz | head

# Count variants in each file
echo "GRCh38 mapped: $(zcat out_sumstat_6_mapping/GRCh38_mapped.gz | tail -n +2 | wc -l)"
echo "Unmapped: $(zcat out_sumstat_6_mapping/unmapped.gz | tail -n +2 | wc -l)"
```

## Use Cases

This example demonstrates:
- Fast variant mapping without full cleaning pipeline
- Identification of novel/unmapped variants
- Handling of different variant types
- Processing mixed chromosome data

The mapping-only workflow is useful when you need:
- Quick dbSNP annotation
- To identify which variants are novel
- Faster processing when full cleaning isn't required
- To prepare data for downstream analyses that only need mapped variants
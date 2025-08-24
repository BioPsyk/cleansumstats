# Investigation: Mapping Risks and Edge Cases in cleansumstats

## Executive Summary

This document investigates potential risks and edge cases where variants in input GWAS summary statistics might fail to map correctly through the cleansumstats dbSNP mapping workflow. Key areas of concern include multi-allelic variants, indels, and various edge cases in variant representation.

## 1. Multi-allelic Variant Handling

### Current Behavior
The cleansumstats pipeline includes a `split_multiallelics_resort_rowindex` process in the mapping workflow, which handles multi-allelic variants by splitting them into separate biallelic records.

### Risks and Considerations

**Low Risk Scenario:**
- When all alleles at a multi-allelic site share the same rsID in dbSNP
- Example: rs123 with alleles A/C/G all map to rs123
- **Impact:** Minimal - all variants map correctly to the same rsID

**Medium Risk Scenario:**
- When different alleles have different rsIDs (rare but possible)
- Example: rs123 for A/C, rs456 for A/G at same position
- **Impact:** May create duplicate position entries with different rsIDs

**Mitigation Strategy:**
```bash
# The pipeline already handles this via:
# 1. split_multiallelics_resort_rowindex - splits multi-allelics
# 2. remove_chrpos_allele_duplicates - removes duplicates
```

## 2. Indel Handling

### Current Limitation
**Critical Finding:** The dbSNP reference used by cleansumstats has filtered out all indels during preprocessing.

### Risks

**High Risk:**
- Input sumstats containing indels will NOT find matches in the dbSNP reference
- These variants will be classified as unmapped
- **Impact:** Complete loss of mapping for insertion/deletion variants

### Proposed Solutions

#### Solution 1: Retain and Liftover Unmapped Indels
```groovy
// In the mapping workflow, add special handling for unmapped variants
workflow handle_unmapped_indels {
  take:
  unmapped_variants
  
  main:
  // Identify indels (REF or ALT length > 1)
  unmapped_variants
    .filter { variant -> 
      variant.ref.length() > 1 || variant.alt.length() > 1 
    }
    .set { indels }
  
  // Apply liftover directly using chain files
  liftover_indels(indels, params.chainFiles)
  
  emit:
  lifted_indels = liftover_indels.out
}
```

#### Solution 2: Create Separate Indel Reference
```bash
# Prepare a separate indel-inclusive dbSNP reference
# This would require modifying the dbSNP preparation pipeline
./cleansumstats.sh prepare-dbsnp --include-indels ...
```

#### Solution 3: Pass-through with Warning
```groovy
// Keep indels with original coordinates, add warning flag
unmapped_variants
  .map { variant ->
    if (is_indel(variant)) {
      variant.mapping_status = "indel_not_mapped"
      variant.warning = "Indels not included in dbSNP reference"
    }
    return variant
  }
```

## 3. Chromosome Notation Mismatches

### Risk
Different notation systems can prevent matching:
- Input: "chr1", dbSNP: "1"
- Input: "23", dbSNP: "X"
- Input: "MT", dbSNP: "M"

### Current Mitigation
The pipeline includes `reformat_chromosome_information` which standardizes chromosome notation.

**Residual Risk:** Low - well handled by existing code

## 4. Genome Build Misdetection

### Risk
Incorrect genome build detection leads to wrong liftover path:
- Ambiguous positions that exist in multiple builds
- Small datasets with insufficient signal for build detection

### Current Mitigation
The `detect_genome_build` process checks positions against multiple builds and uses statistical inference.

### Additional Risk Factors
- **Very small sumstats** (<1000 variants): May not have enough data for reliable detection
- **Filtered sumstats**: Pre-filtered data might lack diagnostic positions
- **Cross-species data**: Non-human data accidentally processed

## 5. Strand Ambiguous Variants

### Risk
A/T and C/G variants can be ambiguous when strand is unknown.

### Impact on Mapping
- Same position might map to different rsIDs depending on strand assumption
- May cause incorrect allele alignment

### Current Handling
The pipeline includes allele standardization, but strand ambiguous variants remain challenging.

## 6. Complex Variants

### Types at Risk
1. **MNPs (Multi-Nucleotide Polymorphisms)**
   - Example: "AC" -> "TG"
   - Risk: May not exist in dbSNP as single entry

2. **Structural Variants**
   - Large insertions/deletions
   - Copy number variants
   - Risk: Not represented in standard dbSNP

3. **Microsatellites/STRs**
   - Repetitive sequences with variable length
   - Risk: Complex representation in different formats

## 7. Position-Only Variants

### Risk
Variants identified only by CHR:POS without rsID or alleles:
- Cannot verify correct variant at multi-allelic sites
- May map to wrong rsID if multiple variants at position

### Mitigation
Require allele information for accurate mapping:
```python
if not variant.has_alleles() and variant.is_multiallelic_position():
    variant.mapping_confidence = "low"
    variant.warning = "Multiple variants at position, mapping uncertain"
```

## 8. Reference Genome Mismatches

### Risk
Reference allele in sumstats doesn't match reference genome:
- Input REF: "A", Reference genome: "G"
- Indicates potential strand flip or reference error

### Detection Strategy
```groovy
// Check reference allele consistency
if (sumstat.ref != dbsnp.ref && sumstat.ref != complement(dbsnp.ref)) {
    flag_as_reference_mismatch()
}
```

## Risk Mitigation Summary

### High Priority (Implement First)
1. **Indel Handling**: Create separate workflow path for indels
2. **Unmapped Tracking**: Always output unmapped variants with reasons
3. **Validation Metrics**: Report mapping success rates by variant type

### Medium Priority
1. **Multi-allelic Resolution**: Enhance logic for complex multi-allelic sites
2. **Strand Detection**: Implement strand ambiguous variant detection
3. **Build Confidence**: Add confidence scores to genome build detection

### Low Priority
1. **Complex Variant Support**: Document limitations clearly
2. **Cross-species Check**: Add species validation
3. **Alternative References**: Support for non-standard reference genomes

## Recommended Implementation Changes

### 1. Enhanced Unmapped Output
```tsv
# unmapped_variants.tsv should include:
chr  pos  ref  alt  reason  suggested_action
1    123  A    T    no_match_in_dbsnp  check_genome_build
2    456  ATCG -    indel_filtered     use_liftover_tool
3    789  A    T    multiallelic_ambiguous  manual_review
```

### 2. Mapping Confidence Scores
Add confidence levels to mapping output:
- **High**: Exact rsID match or unambiguous CHR:POS
- **Medium**: Multi-allelic site with allele match
- **Low**: Position-only match at multi-allelic site
- **None**: No match found

### 3. Variant Type Statistics
Report mapping rates by variant type:
```
Mapping Summary:
- SNPs: 95% mapped (950,000/1,000,000)
- Indels: 0% mapped (0/50,000) - not in reference
- Multi-allelic: 80% mapped (8,000/10,000)
- Ambiguous: 60% mapped (600/1,000)
```

## Conclusion

The main risks for unmappable variants are:

1. **Indels** (100% fail) - Need separate handling strategy
2. **Complex variants** - Not supported by current reference
3. **Multi-allelic ambiguity** - Partial support, needs enhancement
4. **Build misdetection** - Low risk but high impact

The most critical issue is indel handling, which should be addressed by either:
- Creating an indel-inclusive reference
- Implementing direct liftover for unmapped indels
- Clear documentation of this limitation

Other risks are generally well-handled by the existing pipeline but would benefit from enhanced reporting and confidence metrics.
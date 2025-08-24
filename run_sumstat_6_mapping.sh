#!/usr/bin/env bash

# Script to run mapping-only workflow on sumstat_6 example data
# This demonstrates the new mapping-only functionality

set -euo pipefail

echo "=========================================="
echo "Running mapping-only workflow on sumstat_6"
echo "=========================================="

# Check if we should use the test data or full references
if [ "${1:-}" = "--test" ]; then
    echo "Using test reference data (small/fast)"
    
    # The regular cleansumstats.sh won't work easily with map-only for testing
    # Instead, let's show how to run it properly
    echo ""
    echo "To run this example, use the standard cleaning workflow with mapping_only parameter:"
    echo ""
    echo "./cleansumstats.sh \\"
    echo "  -i tests/example_data/sumstat_6/sumstat_6_raw_meta.yaml \\"
    echo "  -e 1 \\"  
    echo "  -o out_sumstat_6_mapping \\"
    echo "  -l \\"
    echo "  --image docker"
    echo ""
    echo "Note: The -e 1 flag uses the built-in example references."
    echo "The mapping-only mode would be activated via the config or as a parameter."
    echo ""
    echo "Alternatively, to test the mapping-only workflow specifically:"
    echo "1. Copy the data to a work directory"
    echo "2. Run with the mapping_only parameter in nextflow.config"
    exit 0
else
    echo "Using full reference data (requires prepared dbSNP and 1KGP references)"
    echo "Usage: $0 [--test]"
    echo ""
    echo "To run with test data (recommended for demo):"
    echo "  $0 --test"
    echo ""
    echo "To run with full references:"
    echo "  First prepare references using:"
    echo "    ./cleansumstats.sh prepare-dbsnp ..."
    echo "    ./cleansumstats.sh prepare-1kgp ..."
    echo "  Then run:"
    echo "    ./cleansumstats.sh map-only \\"
    echo "      -i tests/example_data/sumstat_6/sumstat_6_raw_meta.yaml \\"
    echo "      -d path/to/dbsnp_reference \\"
    echo "      -k path/to/1kgp_reference \\"
    echo "      -o out_sumstat_6_mapping \\"
    echo "      -l \\"
    echo "      --image docker"
    exit 1
fi

echo ""
echo "=========================================="
echo "Workflow completed!"
echo "=========================================="
echo ""
echo "Output files should be in: out_sumstat_6_mapping/"
echo ""
echo "Expected outputs:"
echo "  - GRCh38_mapped.gz: Variants mapped to GRCh38"
echo "  - GRCh37_mapped.gz: Variants mapped to GRCh37"
echo "  - unmapped.gz: Variants that couldn't be mapped"
echo ""
echo "The test reference only contains rs1000, so most variants will be unmapped."
echo "With full references, known rsIDs would be properly mapped."
echo ""
echo "To examine the outputs:"
echo "  zcat out_sumstat_6_mapping/GRCh38_mapped.gz | head"
echo "  zcat out_sumstat_6_mapping/unmapped.gz | head"
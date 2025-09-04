#!/bin/bash
set -e

echo "====================================================================="
echo "Testing applyMapping feature with -e applymapping"
echo "====================================================================="
echo ""

# Clean up previous test
rm -rf out_test_applymapping

# Run the test
echo "1. Running quicktest: ./cleansumstats.sh -e applymapping -j docker"
./cleansumstats.sh -e applymapping -j docker > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "   ❌ FAILED: Pipeline execution failed"
    exit 1
fi
echo "   ✓ Pipeline completed successfully"
echo ""

# Check if mapping_results.tsv.gz was created
echo "2. Checking if mapping_results.tsv.gz was created..."
if [ ! -f "out_test_applymapping/mapping_results.tsv.gz" ]; then
    echo "   ❌ FAILED: mapping_results.tsv.gz not found"
    exit 1
fi
echo "   ✓ mapping_results.tsv.gz exists"
echo ""

# Check the number of lines (should be 11: 1 header + 10 data rows)
echo "3. Verifying row count..."
line_count=$(gzip -d -c out_test_applymapping/mapping_results.tsv.gz | wc -l | xargs)
if [ "$line_count" != "11" ]; then
    echo "   ❌ FAILED: Expected 11 lines, got $line_count"
    exit 1
fi
echo "   ✓ Correct number of rows: $line_count"
echo ""

# Check that row indices are 1-10
echo "4. Verifying row indices are sequential 1-10..."
indices=$(gzip -d -c out_test_applymapping/mapping_results.tsv.gz | tail -n +2 | cut -f1 | tr '\n' ' ')
expected="1 2 3 4 5 6 7 8 9 10 "
if [ "$indices" != "$expected" ]; then
    echo "   ❌ FAILED: Row indices don't match"
    echo "   Expected: $expected"
    echo "   Got: $indices"
    exit 1
fi
echo "   ✓ Row indices are correct (1-10)"
echo ""

# Check mapping status counts
echo "5. Checking mapping statistics..."
mapped_count=$(gzip -d -c out_test_applymapping/mapping_results.tsv.gz | tail -n +2 | cut -f2 | grep -c "^mapped$" || true)
unmapped_count=$(gzip -d -c out_test_applymapping/mapping_results.tsv.gz | tail -n +2 | cut -f2 | grep -c "^unmapped$" || true)

if [ "$mapped_count" != "6" ]; then
    echo "   ❌ FAILED: Expected 6 mapped variants, got $mapped_count"
    exit 1
fi
if [ "$unmapped_count" != "4" ]; then
    echo "   ❌ FAILED: Expected 4 unmapped variants, got $unmapped_count"
    exit 1
fi
echo "   ✓ Mapped variants: $mapped_count"
echo "   ✓ Unmapped variants: $unmapped_count"
echo ""

# Test alignment with paste
echo "6. Testing alignment with paste command..."
# Count lines when pasting (should be 11: header + 10 data rows)
paste_lines=$(paste tests/e2e/maponly_basics/sumstats.txt <(gzip -d -c out_test_applymapping/mapping_results.tsv.gz) | wc -l | xargs)

if [ "$paste_lines" != "11" ]; then
    echo "   ❌ FAILED: Expected 11 lines after paste, got $paste_lines"
    exit 1
fi
echo "   ✓ Files align correctly with paste"
echo ""

# Verify specific mapped variants
echo "7. Verifying specific variant mappings..."
# Check that rs10159252 is mapped at row 2
row2=$(gzip -d -c out_test_applymapping/mapping_results.tsv.gz | sed -n '3p')
if ! echo "$row2" | grep -q "2.*mapped.*rs10159252.*1:84824814"; then
    echo "   ❌ FAILED: rs10159252 not correctly mapped at row 2"
    echo "   Got: $row2"
    exit 1
fi
echo "   ✓ rs10159252 correctly mapped at row 2"

# Check that rs10090539 is mapped at row 10
row10=$(gzip -d -c out_test_applymapping/mapping_results.tsv.gz | tail -1)
if ! echo "$row10" | grep -q "10.*mapped.*rs10090539.*8:126332207"; then
    echo "   ❌ FAILED: rs10090539 not correctly mapped at row 10"
    echo "   Got: $row10"
    exit 1
fi
echo "   ✓ rs10090539 correctly mapped at row 10"
echo ""

# Show example of paste output
echo "8. Example output with paste (first 3 data rows):"
echo "   ----------------------------------------------"
paste tests/e2e/maponly_basics/sumstats.txt <(gzip -d -c out_test_applymapping/mapping_results.tsv.gz) | head -4 | cut -f1-3,12-16 | column -t
echo ""

echo "====================================================================="
echo "✅ ALL TESTS PASSED!"
echo "====================================================================="
echo ""
echo "The applyMapping feature works correctly:"
echo "  - Preserves original row order (1-10)"
echo "  - Creates mapping_results.tsv.gz file"
echo "  - Correctly identifies 6 mapped and 4 unmapped variants"
echo "  - Aligns perfectly with original file using paste"
echo ""
echo "Usage: ./cleansumstats.sh -e applymapping -j docker"
echo "====================================================================="
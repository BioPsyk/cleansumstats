# Troubleshooting

## input sumstat is not accepted
cleansumstats accepts all sumstats that are space separated with the same number of columns in every row. Sometimes the format is different. Here are some ways of debugging and reshaping your sumstats.

### Input is not using space separation
For example it is not uncommon that the input format is comma separated. This is how you spot it, and how you reshape the sumstat using awk. If you detect something else than `,` ,then just replace the comma in `-FS=","` to the character in your sumstat file.
```
# Visually inspect the file
zcat inputfile.gz | head

# Replace all commas with tab separation
zcat  inputfile.gz | awk -vFS="," -vOFS="\t" '{for(k=1; k <= NF-1; k++){printf "%s%s", $(k), OFS }; print $(NF)}' | gzip -c > newinputfile.gz

```

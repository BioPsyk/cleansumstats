af1kgvcf=$1

#remove indels and extract the population frequency
echo -e "CHRPOS\tREF\tALT\tEAS\tEUR\tAFR\tAMR\tSAS"
bcftools query -f '%CHROM:%POS\t%REF\t%ALT\t%INFO/EAS_AF\t%INFO/EUR_AF\t%INFO/AFR_AF\t%INFO/AMR_AF\t%INFO/SAS_AF\n' ${af1kgvcf} | awk 'length($2)==1 && length($3)==1{print $0}'


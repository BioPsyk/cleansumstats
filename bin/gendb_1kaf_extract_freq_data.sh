af1kgvcf=$1
ftype=$2

#remove indels and extract the population frequency
if [ "${ftype}" == "" ] || [ "${ftype}" == "original" ]; then
  echo -e "CHRPOS\tREF\tALT\tEAS\tEUR\tAFR\tAMR\tSAS"
  bcftools query -f '%CHROM:%POS\t%REF\t%ALT\t%INFO/EAS_AF\t%INFO/EUR_AF\t%INFO/AFR_AF\t%INFO/AMR_AF\t%INFO/SAS_AF\n' ${af1kgvcf} | awk 'length($2)==1 && length($3)==1{print $0}'
elif [ "${ftype}" == "2024-09-11-1000GENOMES-phase_3.vcf" ]; then
  echo -e "CHRPOS\tREF\tALT\tEAS\tEUR\tAFR\tAMR\tSAS"
  # additionally remove duplicates
  bcftools query -f '%CHROM:%POS\t%REF\t%ALT\t%INFO/EAS\t%INFO/EUR\t%INFO/AFR\t%INFO/AMR\t%INFO/SAS\n' ${af1kgvcf} \
	  | awk 'length($2)==1 && length($3)==1 {print $0}' \
	  | awk '!seen[$1,$2,$3]++'
else
  echo "not valied ftype for allele frequeucy extraction"
  exit 1
fi

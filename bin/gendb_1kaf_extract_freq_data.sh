#!/usr/bin/env bash

af1kgvcf=$1
ftype=$2

#remove indels and extract the population frequency
if [ "${ftype}" == "" ] || [ "${ftype}" == "original" ]; then
  echo -e "CHRPOS\tREF\tALT\tEAS\tEUR\tAFR\tAMR\tSAS"
  awk '
    BEGIN { FS="\t" }
    /^[^#]/ {
      ref=$4
      alt=$5
      
      # Extract AF values from INFO field
      split($8, info, ";")
      for (i in info) {
        if (info[i] ~ /EAS_AF=/) eas = substr(info[i], 8)
        if (info[i] ~ /EUR_AF=/) eur = substr(info[i], 8)
        if (info[i] ~ /AFR_AF=/) afr = substr(info[i], 8)
        if (info[i] ~ /AMR_AF=/) amr = substr(info[i], 8)
        if (info[i] ~ /SAS_AF=/) sas = substr(info[i], 8)
      }
      
      if (length(ref)==1 && length(alt)==1) {
        printf "%s:%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
          $1, $2, ref, alt, eas, eur, afr, amr, sas
      }
    }
  ' ${af1kgvcf}
elif [ "${ftype}" == "2024-09-11-1000GENOMES-phase_3.vcf" ]; then
  echo -e "CHRPOS\tREF\tALT\tEAS\tEUR\tAFR\tAMR\tSAS"
  awk '
    BEGIN { FS="\t" }
    /^[^#]/ {
      ref=$4
      alt=$5
      
      # Extract AF values from INFO field
      split($8, info, ";")
      for (i in info) {
        if (info[i] ~ /EAS=/) eas = substr(info[i], 5)
        if (info[i] ~ /EUR=/) eur = substr(info[i], 5)
        if (info[i] ~ /AFR=/) afr = substr(info[i], 5)
        if (info[i] ~ /AMR=/) amr = substr(info[i], 5)
        if (info[i] ~ /SAS=/) sas = substr(info[i], 5)
      }
      
      # Track seen variants to remove duplicates
      key = $1 ":" $2 SUBSEP ref SUBSEP alt
      if (length(ref)==1 && length(alt)==1 && !seen[key]++) {
        printf "%s:%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
          $1, $2, ref, alt, eas, eur, afr, amr, sas
      }
    }
  ' ${af1kgvcf}
else
  echo "not valid ftype for allele frequency extraction" >&2
  exit 1
fi

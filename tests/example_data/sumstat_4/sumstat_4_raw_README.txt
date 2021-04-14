To limit the possibilities of identifiability, significant digits for betas and standard errors are restrcted to three decimal places, and no sample allele frequencies are provided (the reported allele frequencies are from the CEU, GBR and TSI populations in the 1000G sample).

For SNPs passing quality control, we provide results from these four meta-analyses:

1. SWB_Full.txt --- subjective well-being meta-analysis of all cohorts except 23andMe. All SNPs.
2. SWB_10K.txt --- subjective well-being meta-analysis of all cohorts. Pruned set of 10,000 SNPs. 
3. Neuroticism_Full.txt --- neuroticism meta-analysis of all cohorts. All SNPs.
4. DS_Full.txt --- depressive symptoms meta-analysis of all cohorts. All SNPs.

Each file consists of the following columns:

MarkerName: SNP rs number.
CHR: chromosome number.
POS: base pair position.
A1: effect allele.
A2: other allele.
EAF: A1 frequency in 1000G sample (CEU, GBR and TSI individuals).
Beta: Standardized regression coefficient. 
SE: standard error of beta.
Pval: Nominal p-value of the null hypothesis that the coefficient is equal to zero.

By downloading these data, you acknowledge they will be used for research purposes and that you are in compliance with applicable rules, policies and regulations.

For additional details, please see the Supplementary Note accompanying Okbay et al. (2016).  

Okbay A et al. “Genetic variants associated with subjective well-being, depressive symptoms and neuroticism identified through genome-wide analyses.” Nature Genetics. DOI: 10.1038/ng.3552

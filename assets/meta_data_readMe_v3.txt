########################################################################
# 
#     A critical part of our GWAS sumstats cleaning pipeline is accurate meta-data
#  for each study.  This meta-data give critical input to the cleaning pipeline,
#  allows us to annotate and organize studies, and collects information that is
#  critical for down stream uses of the sum stats.
# 
#     It is critical the information is filled out accurately and completely.  There 
#  are some automated checks, but it is not possible to computationally validate all
#  pieces of info, so please fill out with care!
# 
#     In addition to this meta data, we need the actual sum stats file, any associated
#  readme files, and a pdf of the publication (potentially relevant supplementary 
#  information as well).
# 
########################################################################

########################################################################
# 
#  Notes:
#  -If data is missing or unavailable enter "missing"
#  -Each variable should be on one line
# 
########################################################################

########################################################################
#  Meta data section 1 - Study Descriptors
########################################################################

study_PMID=
# Pubmed id of associated publication.  If based on a preprint such as biorXiv, indicate preprint.  
# If preprint of missing, record extra data in study_Use, study_Controller, study_Contact, study_Restrictions.
# options: <number>, preprint, missing 
# example: study_PMID=30323354

study_Year=
# Year of publication.
# options: <number> 
# example: study_Year=2018


study_PhenoDesc=
# Phenotype description.  Should be as faithful to the name of the phenotype used in the publication.  This
# will not be standardized, but should aim to be more inclusive, informative and complete.  Can be a full sentence.
# options: <character string>
# example: Parental proxy diagnosis or clinically defined Alzheimer's Disease
# example: Schiziphrenia
# example: Education attainment, measured in years of schooling

study_PhenoCode=
# Standard, in house trait identifier.  Must be in the in house-ontology.
# ontology:
# options: <character string from ontology>
# example:

study_PhenoMod=
# Standard IBP phenotype modifier codes that are used to identify different versions of the same phenotype/PMID combination.
# This is relevant when, for example, sum stats are recomputed excluding iPSYCH, in males only, or with/without specific 
# covariates.
# Code must be in the in-house ontology.
# ontology: 
# options: <character string from ontology>, missing
# example:


study_FileURL=
# Direct weblink to sumstats.
# options: <web URL>, missing
# example:

study_AccessDate=
# Year_Month_Date of access of sum stats. 4 digit year, 2 digit month, 2 digit date, underscore separator.
# options: <number_number_number>
# example:2020_04_16

study_Use=
# Can these sumstats be used by the general public or are they private/with some restrictions?
# options: public, private, preprint
# study_Use=public

study_Controller=
# If private, Name of person responsible for sum stats.  Use "missing" if "public".
# options: <character string>, <preprint publication URL link>, missing
# example: study_Controller=Andrew Schork
# example: study_Controller=www.biorxiv.org/content/10.1101/240911v1
# example: study_Controller=missing

study_Contact=
# If private, email address of person responsible for sum stats.  Use "missing" if "public" or "preprint".
# options: <email address>, missing
# example: study_Contact=Andrew.Schork@regionh.dk 
# example: study_Contact=missing

study_Restrictions=
# If private, describe terms of use.  Use "missing" if "public" or "preprint".
# options: <character string>, missing
# example: study_Restrictions=Sumstats can only be used with permission of controller until embargo date of May 12, 2021.
# example: study_Restrictions=missing


study_inHouseData=
# If iPSYCH data, or some other in house data set that we analyze, is in this study, then this is very important to mark.  
# List of studies to watch out for is provided.
# ontology: 
# options: <character string from ontology>, missing
# example: study_inHouseData=iPSYCH

study_Ancestry=
# It is important to note the genetic ancestry of the subjects in the study. An ontology of populations is provided.
# ontology: 
# options: <character string from ontology>, missing
# example: study_Population=EUR

study_Gender=
# What is the gender composition of the study?
# options: male, female, mixed
# example: study_Gender=mixed

study_ImputePanel=
# What data set was this study imputed to? If a meta-analysis with multiple, not meta.
# options: HapMap2, HapMap2, 1KGP_pilot, 1KGP_v1, 1KGP_v2, 1KGP_v3, 1KGP_v4, 1KGP_v5, TOPMED, HRC, meta
# example: study_ImputePanel=HRC

study_ImputeSoftware=
# What software were use to phase and impute, comma separate values? if multiple as part of a meta, use meta.
# options: <character string>, <character string>; meta, meta
# example: study_ImputeSoftware=meta, meta
# example: study_ImputeSoftware=ShapeIt2, Impute 2

study_Array=
# What array was used for genotyping? is multiple, choose meta.
# options: <character string>, meta
# example: study_Array=PsychArray
# example: study_Array=meta


study_Notes=
# If there are special notes that you feel need to be included, please add them here.
# options: <character string>, missing
# example: study_Notes=missing

########################################################################
#  Meta data section 2 - Statistical Descriptors
########################################################################

stats_TraitType=
# Is the trait quantitative (qt), ordinal (ord), or case-control (cc), something else?
# options: qt, ord, cc, ?
# example: stats_traitType=qt

stats_Model=
# What model was used to generate the sum stats? logistic (log), linear (lin), 
# linear mixed model (linMM), logistic mixed model (logMM), others?
# options: log, lin, linMM, logMM
# example: stats_Model=logMM


stats_TotalN=
# Total sample size (cases and controls).  
# ***USE CARE*** This number may not be the one in the abstract/methods.  Check
# sum stats readme files and supplementary notes describing data release as sometimes public sum stats
# data is censored and only a subset of the data used in the printed paper. Very tricky!
# options: <number>
# example: stats_TotalN=12000

stats_CaseN=
# Total number of cases in study
# options: <number>
# example: stats_CaseN=4000

stats_ControlN=
#  Total number of controls in study, example: stats_ControlN=7448
# options: <number>
# example: stats_ControlN=8000


stats_GCAdjust=
Were stats adjusted post-hoc by some version of Genomic Control?
# options: T,F
# example: stats_GCAdjust=F

stats_GCMethod=
# If GCAdjust is TRUE, which GC control method was used.  Could be Genomic Control (GC), or ..., or unknown
# options: <character string>, missing
# example: stats_GCMethod=GC

stats_GCValue=
# If GCAdjust is TRUE, what was the adjustment factor?
# options: <number>
# example: stats_GCValue=1.4


stats_Notes=
# If there are special notes that you feel need to be included, please add them here.
# options: <character string>, missing
# example: stats_Notes=missing

########################################################################
#  Meta data section 3 - SumStats File Descriptors
########################################################################

col_CHR=
# Column where the chromosome information is in. It is ok if it comes embedded in a joined 
# position vector like 1:2444, 1_1244 or 1_234:a:t. An internal algorithm will split 
# out the correct value. 
# options: <character string>, missing
# example: col_CHR=CHR

col_POS=
# Base pair positions. It is ok if it comes embedded in a joined 
# position vector like 1:2444, 1_1244 or 1_234:a:t. An internal algorithm will split 
# out the correct value.
# options: <character string>, missing
# example:

col_SNP=
# RSID identifiers if available, otherwise the column for the unique SNP identifier
# options: <character string>, missing
# example: col_SNP=rsID
# example: col_SNP=SNP

col_EffectAllele=
# The effect allele. It is ok if it comes embedded in a joined 
# position vector like 1_234:a:t. An internal algorithm will split 
# out the correct value. Do NOT assume A1=EffectAllele.  Check carefully.
# options: <character string>, missing
# example: col_OtherAllele=A1

col_OtherAllele=
# The non effect allele. It is ok if it comes embedded in a joined 
# position vector like 1_234:a:t. An internal algorithm will split 
# out the correct value.  Do NOT assume A2=OtherAllele.  Check carefully.
# options: <character string>, missing
# example: col_OtherAllele=A2

col_BETA=
# The beta estimate (per allele effect).  Can be an ln(OR) for case control trait or linear coefficient.
# options: <character string>, missing
# example: col_BETA=B

col_SE=
# The standard error of the beta column.  Sometimes an SE is given with an OR - this is typically on the ln(OR) 
# scale, and should be reported here.  Check carefully.
# options: <character string>, missing
# example: col_SE=SE

col_OR=
# The odds ratio column
# options: <character string>, missing
# example: col_OR=OR

col_ORL95=
# The odds ratio lower 95th percentile of confidence interval.  May not be present - will be missing for
# linear models, or an SE may be provide with an OR.  in that case, it is likely the SE of the ln(OR) and should
# be reported in the col_SE.  Check carefully.
# options: <character string>, missing
# example: col_ORL95=OR_lowerCI

col_ORU95=
# The odds ratio upper 95th percentile of confidence interval.  May not be present - will be missing for
# linear models, or an SE may be provide with an OR.  in that case, it is likely the SE of the ln(OR) and should
# be reported in the col_SE.  Check carefully.
# options: <character string>, missing
# example: col_ORU95=OR_upperCI

col_Z=
# The Z-score column.  Could be called a wild or t-statistic or just stat.
# options: <character string>, missing
# example: col_Z=Z

col_P=
# The P-value column
# options: <character string>, missing
# example: col_P=pval

col_N=
# The columns for the per variant number of individuals.  Sometimes referred to as number non-missing.
# options: <character string>, missing
# example: col_N=n

col_CaseN=
# The number of used individuals as cases for this variant
# options: <character string>, missing
# example: col_CaseN=n_Cases

col_ControlN=
# The number of used individuals as controls for this variant
# options: <character string>, missing
# example: col_ControlN=n_controls

col_AFREQ=
# The allele frequency of the used individuals for the test of this variant.  Do not include reference data
# allele frequencies, only if the actual study sample frequencies are presented.
# options: <character string>, missing
# example: col_AFREQ=A1_FRQ

col_INFO=
# The specific info-score for this variant.  INFO scores reflect imputation quality.  
# Do not use "minimum INFO" for meta-analysis.  Include only if it reflects
# the INFO for all data points (for a meta, this could be an INFO score derived post hoc from individual 
# study INFO scores.
# options: <character string>, missing
# example: col_INFO=INFO


col_Notes=
# If there are special notes that you feel need to be included, please add them here.
# ***USE CARE*** Please note if the A1 was FORCED to be effect allele because of bad documentation.
# options: <character string>, missing
# example: col_Notes=Effect allele assumed to be A1, but documentation was ambiguous.

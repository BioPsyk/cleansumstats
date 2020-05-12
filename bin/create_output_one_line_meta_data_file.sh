newMefl=$1
outFile=$2

# Keep all mandatory fields
colForOneLineMetaFile=(
version
sumstat_ID
run_user
run_date
path_sumStats
path_readMe
path_pdf
path_pdfSupp
study_PMID
study_Year
study_PhenoDesc
study_PhenoCode
study_PhenoMod
study_FilePortal
study_FileURL
study_AccessDate
study_Use
study_Controller
study_Contact
study_Restrictions
study_inHouseData
study_Ancestry
study_Gender
study_PhasePanel
study_PhaseSoftware
study_ImputePanel
study_ImputeSoftware
study_Array
study_Notes
stats_TraitType
stats_Model
stats_TotalN
stats_CaseN
stats_ControlN
stats_GCMethod
stats_GCValue
stats_Notes
col_CHR
col_POS
col_SNP
col_EffectAllele
col_OtherAllele
col_BETA
col_SE
col_OR
col_ORL95
col_ORU95
col_Z
col_P
col_N
col_CaseN
col_ControlN
col_AFREQ
col_INFO
col_Direction
col_Notes
)

#
# Make header
#
printf "%s\t" "cleansumstats_date" > ${outFile}

# Add all variables in same order as above
for var in ${colForOneLineMetaFile[@]}; do
   printf "%s\t" "${var}" >> ${outFile}
done

printf "%s\n" "cleansumstats_user" >> ${outFile}

#
# Make content
#

# Add DATE as first column
dateOfCreation="$(date +%F-%H%M)"
printf "%s\t" "${dateOfCreation}" >> ${outFile}

# Add all variables in same order as above
for var in ${colForOneLineMetaFile[@]}; do
   Px="$(grep "^${var}=" $newMefl)"
   P="$(echo "${Px#*=}")"
   printf "%s\t" "${P}" >> ${outFile}
done

printf "%s\n" "${USER}" >> ${outFile}


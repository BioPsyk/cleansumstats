newMefl=$1
outFile=$2

# Keep all mandatory fields
colForOneLineMetaFile=(
cleansumstats_date
cleansumstats_ID
study_PMID
study_Year
study_PhenoDesc
study_PhenoCode
study_PhenoMod
study_FileURL
study_FilePortal
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
path_sumStats
path_readMe
path_pdf
cleansumstats_metafile_date
cleansumstats_metafile_user
cleansumstats_version
)

# Add headers for all vars above
for var in ${colForOneLineMetaFile[@]}; do
   printf "%s\t" "${var}" >> ${outFile}
done
printf "%s\n" "${var}" >> ${outFile}

# Add all variable values in same order as above
for var in ${colForOneLineMetaFile[@]}; do
   Px="$(grep "^${var}=" $newMefl)"
   P="$(echo "${Px#*=}")"
   printf "%s\t" "${P}" >> ${outFile}
done

# Let the last element end with newline
Px="$(grep "^cleansumstats_user=" $newMefl)"
P="$(echo "${Px#*=}")"
printf "%s\n" "${P}" >> ${outFile}


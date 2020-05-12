oldMefl=$1
toReplaceOrExtend=$2

# Keep all mandatory fields
colNeededInMetaOutfile=(
version
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
sumstat_ID
)
# Add user input if not present in "to replace or extend"
for var in ${colNeededInMetaOutfile[@]}; do
   if grep -Pq "^${var}=" ${toReplaceOrExtend}
   then
     grep -P "^${var}=" ${toReplaceOrExtend}
   else
     grep -P "^${var}=" ${oldMefl}
   fi
done




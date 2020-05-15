oldMefl=$1
toReplaceOrExtend=$2

# Stamp the new meta file with date and sumstat user
dateOfCreation="$(date +%F-%H%M)"
printf "%s\n" "cleansumstats_date=${dateOfCreation}"
printf "%s\n" "cleansumstats_user=${USER}"

# Keep all mandatory fields
colNeededInMetaOutfile1=(
cleansumstats_ID
cleansumstats_version
cleansumstats_metafile_user
cleansumstats_metafile_date
path_sumStats
path_readMe
path_pdf
)

# Add user input if not present in "to replace or extend"
for var in ${colNeededInMetaOutfile1[@]}; do
   if grep -Pq "^${var}=" ${toReplaceOrExtend}
   then
     grep -P "^${var}=" ${toReplaceOrExtend}
   else
     grep -P "^${var}=" ${oldMefl}
   fi
done

#for pdfSupp we only replace as it can have multiple lines
grep -P "^path_pdfSupp=" ${toReplaceOrExtend} 

colNeededInMetaOutfile2=(
path_original_sumStats
path_original_readMe
path_original_pdf
)

# Add user input if not present in "to replace or extend"
for var in ${colNeededInMetaOutfile2[@]}; do
   if grep -Pq "^${var}=" ${toReplaceOrExtend}
   then
     grep -P "^${var}=" ${toReplaceOrExtend}
   else
     grep -P "^${var}=" ${oldMefl}
   fi
done

#for original_pdfSupp we only replace as it can have multiple lines
grep -P "^path_original_pdfSupp=" ${toReplaceOrExtend} 

colNeededInMetaOutfile3=(
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

# Add user input if not present in "to replace or extend"
for var in ${colNeededInMetaOutfile3[@]}; do
   if grep -Pq "^${var}=" ${toReplaceOrExtend}
   then
     grep -P "^${var}=" ${toReplaceOrExtend}
   else
     grep -P "^${var}=" ${oldMefl}
   fi
done



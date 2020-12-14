newMefl=$1
outFile=$2
inventory=$3

# Keep all mandatory fields
colForOneLineMetaFile=(
cleansumstats_date
cleansumstats_ID
study_PMID
study_Year
study_PhenoDesc
study_PhenoCode
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

#BETTER TO NOT DO IT LIKE THIS, we should just get one line, that is best

# Sumstat ID
#SIDx="$(grep "^cleansumstats_ID=" $newMefl)"
#SID="$(echo "${SIDx#*=}")"

# Add a row for each time this ID has been run before
#count="$(ls -1 ${inventory} | wc -l)"
#if [ "${count}" -gt 0 ]
#then
#  mostrecentfile="$(ls -1 ${inventory}/*_inventory.txt | awk '{old=$1; sub(".*/","",$1); gsub("-","",$1); print $1, old}' | sort -rn -k1.1,1.23 | awk '{print $2}' | head -n1 )"
#  awk -vFS="\t" -vOFS="\t" -vSID=${SID} '$2==SID{print $0}' ${mostrecentfile} >> ${outFile}
#else
#  :
#fi

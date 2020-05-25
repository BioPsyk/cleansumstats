oldMefl=$1
toReplaceOrExtend=$2
newSumstatHeaderFile=$3

# Stamp the new meta file with date and sumstat user
dateOfCreation="$(date +%F-%H%M)"
printf "%s\n" "cleansumstats_date=${dateOfCreation}"
printf "%s\n" "cleansumstats_user=${USER}"

# Keep all mandatory fields
colNeededInMetaOutfile1=(
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
stats_EffectiveN
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

colNeededInMetaOutfile1b=(
cleansumstats_ID
cleansumstats_version
cleansumstats_metafile_user
cleansumstats_metafile_date
cleansumstats_cleaned_GRCh37
cleansumstats_cleaned_GRCh38_coordinates
)

# Add user input if not present in "to replace or extend"
for var in ${colNeededInMetaOutfile1b[@]}; do
   if grep -Pq "^${var}=" ${toReplaceOrExtend}
   then
     grep -P "^${var}=" ${toReplaceOrExtend}
   else
     grep -P "^${var}=" ${oldMefl}
   fi
done

#Col names in the cleaned data Always present
printf "%s\n" "cleansumstats_col_RAWROWINDEX=0"
printf "%s\n" "cleansumstats_col_CHR=CHR"
printf "%s\n" "cleansumstats_col_POS=POS"
printf "%s\n" "cleansumstats_col_SNP=RSID"
printf "%s\n" "cleansumstats_col_EffectAllele=EffectAllele"
printf "%s\n" "cleansumstats_col_OtherAllele=OtherAllele"

#check what stat cols exist in the final output
colNeededInMetaOutfile4=(
  cleansumstats_col_BETA=B
  cleansumstats_col_SE=SE
  cleansumstats_col_OR=OR
  cleansumstats_col_ORL95=ORL95
  cleansumstats_col_ORU95=ORU95
  cleansumstats_col_Z=Z
  cleansumstats_col_P=P
  cleansumstats_col_N=N
  cleansumstats_col_CaseN=CaseN
  cleansumstats_col_ControlN=ControlN
  cleansumstats_col_AFREQ=AFREQ
  cleansumstats_col_INFO=INFO
  cleansumstats_col_Direction=Direction
)


header=($(cat ${newSumstatHeaderFile} | awk '
  function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
  function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
  function trim(s)  { return rtrim(ltrim(s)); }
  
  NR==1{tr=trim($0); print tr}'))

function selRightHand(){
  echo "${1#*=}"
}

function selLeftHand(){
  echo "${1%=*}"
}

function existInHeader(){
  if echo ${2} | grep -q "${1}"
  then
      echo true
  else
      echo false
  fi
}

for var in ${colNeededInMetaOutfile4[@]}; do
  right="$(selRightHand ${var})"
  left="$(selLeftHand ${var})"
  gotHit="false"
  for hc in ${header[@]}; do
    #echo $hc
    if [ $(existInHeader ${hc} ${right}) == "true" ]
    then
      gotHit="true"
    else
      :
    fi
  done
  if [ ${gotHit} == "false" ]
  then
    printf "%s\n" "${left}=missing"
  else
    printf "%s\n" "${var}"
  fi
done

# Add cleansumstats notes
printf "%s\n" "cleansumstats_col_Notes=If possible, missing stats have been calculated from the avialable. If OtherAllele was missing we use the alternate allele according to the dbsnp reference"




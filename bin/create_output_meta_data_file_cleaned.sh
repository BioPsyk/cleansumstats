toADD=$1
newSumstatHeaderFile=$2


#add everything in file $toADD
cat ${toADD}

#Col names in the cleaned data Always present
printf "%s\n" "cleansumstats_col_RAWROWINDEX: 0"
printf "%s\n" "cleansumstats_col_CHR: CHR"
printf "%s\n" "cleansumstats_col_POS: POS"
printf "%s\n" "cleansumstats_col_SNP: RSID"
printf "%s\n" "cleansumstats_col_EffectAllele: EffectAllele"
printf "%s\n" "cleansumstats_col_OtherAllele: OtherAllele"

#check what stat cols exist in the final output
colNeededInMetaOutfile4=(
  'cleansumstats_col_BETA: B'
  'cleansumstats_col_SE: SE'
  'cleansumstats_col_OR: OR'
  'cleansumstats_col_ORL95: ORL95'
  'cleansumstats_col_ORU95: ORU95'
  'cleansumstats_col_Z: Z'
  'cleansumstats_col_P: P'
  'cleansumstats_col_N: N'
  'cleansumstats_col_CaseN: CaseN'
  'cleansumstats_col_ControlN: ControlN'
  'cleansumstats_col_EAF: EAF'
  'cleansumstats_col_INFO: INFO'
  'cleansumstats_col_Direction: Direction'
)

header=($(cat ${newSumstatHeaderFile} | awk '
  function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
  function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
  function trim(s)  { return rtrim(ltrim(s)); }

  NR==1{tr=trim($0); print tr}'))

function selRightHand(){
  echo "${1#*: }"
}

function selLeftHand(){
  echo "${1%: *}"
}

function existInHeader(){
  if echo ${2} | grep -q "${1}"
  then
      echo true
  else
      echo false
  fi
}

for var in "${colNeededInMetaOutfile4[@]}"; do
  right="$(selRightHand ${var})"
  left="$(selLeftHand ${var})"
  gotHit="false"
  for hc in "${header[@]}"; do
    #echo $hc
    if [ $(existInHeader "${hc}" "${right}") == "true" ]
    then
      gotHit="true"
    else
      :
    fi
  done
  if [ "${gotHit}" == "true" ]
  then
    printf "%s\n" "${var}"
  fi
done

# Add cleansumstats notes
printf "%s\n" "cleansumstats_col_Notes: If possible, missing stats have been calculated from the avialable. If OtherAllele was missing we use the alternate allele according to the dbsnp reference"

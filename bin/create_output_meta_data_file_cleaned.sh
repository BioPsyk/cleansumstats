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
  'cleansumstats_col_CaseEAF: CaseEAF'
  'cleansumstats_col_ControlEAF: ControlEAF'
  'cleansumstats_col_INFO: INFO'
  'cleansumstats_col_Direction: Direction'
)

function trimwhitespace(){
  awk '
    function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
    function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
    function trim(s)  { return rtrim(ltrim(s)); }
  
    {tr=trim($0); print tr}'
}

header=($(cat ${newSumstatHeaderFile} | trimwhitespace))

function selRightHand(){
  echo "${1}" | awk '{gsub(/.*: /,""); print}'
}

function selLeftHand(){
  echo "${1}" | awk '{gsub(/: .*/,""); print}'
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
  right="$(selRightHand "${var}" | trimwhitespace)"
  left="$(selLeftHand "${var}" | trimwhitespace)"
  gotHit="false"
  #echo "$left AND $right"
  for hc in "${header[@]}"; do
    #echo "test:$hc,with:"${left}""
    if [ "${hc}" == "${right}" ]
    then
      gotHit="true"
      #echo "hit: $hc, with: "${right}""
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

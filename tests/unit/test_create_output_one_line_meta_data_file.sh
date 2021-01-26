#!/usr/bin/env bash

set -euo pipefail

test_script="create_output_one_line_meta_data_file"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

mkdir "${initial_dir}"
cd "${initial_dir}"

#=================================================================================
# Helpers
#=================================================================================

function _setup {
  mkdir "${1}"
  cd "${1}"
  mkdir inventory
  curr_case="${1}"
}

function _run_script {
  set +e

  "${test_script}.sh" ./metadata.txt ./result ./inventory;
  script_result="$?"

  tr '\t' '\n' < ./result > ./result_linebreak

  if [[ "${script_result}" != 0 ]]; then
    echo "- [FAIL] ${curr_case}: Script exited with: ${script_result}"
    exit 1
  fi

  diff -u ./expected_result_linebreak ./result_linebreak

  if [[ "$?" != 0 ]]; then
    echo "[FAIL] ${curr_case}: Unexpected result"
    exit 1
  fi

  set -e

  echo "- [OK] ${curr_case}"
  cd "${initial_dir}"
}

function _write_valid_metadata {
  cat <<EOF > ./metadata.txt
cleansumstats_date=2021-01-20
cleansumstats_ID=2123
study_PMID=2
study_Year=2020
study_PhenoDesc=asdad
study_PhenoCode=asdad
study_FileURL=asdad
study_FilePortal=asdad
study_AccessDate=2020_01_20
study_Use=open
study_Controller=www.biorxiv.org/content/10.1101/240911v1
study_Contact=Andrew.Schork@regionh.dk
study_Restrictions=Can only be used when the planets are aligned
study_inHouseData=oASTRO
study_Ancestry=MARS
study_Gender=missing
study_PhasePanel=starbucks
study_PhaseSoftware=Cat1.5
study_ImputePanel=ikea
study_ImputeSoftware=Dog9.0
study_Array=the best one
study_Notes=No, I forgot take notes in class
stats_TraitType=Stuff
stats_Model=Jepp
stats_TotalN=25
stats_CaseN=2
stats_ControlN=23
stats_GCMethod=astrology
stats_GCValue=3.50
stats_Notes=Notes about stats
col_CHR=chr
col_POS=pos
col_SNP=snp
col_EffectAllele=a1
col_OtherAllele=a2
col_BETA=b
col_SE=se
col_OR=or
col_ORL95=orl95
col_ORU95=oru95
col_Z=z
col_P=pval
col_N=n
col_CaseN=case_n
col_ControlN=control_n
col_EAF=eaf
col_OAF=oaf
col_INFO=info
col_Direction=dir
col_Notes=notes
path_sumStats=missing
path_readMe=readme.md
path_pdf=missing
cleansumstats_metafile_date=2021-01-20
cleansumstats_metafile_user=jesgad
cleansumstats_version=0.1-beta
EOF
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using all needed fields

_setup "all_needed"

_write_valid_metadata

cat <<EOF > ./expected_result
cleansumstats_date	cleansumstats_ID	study_PMID	study_Year	study_PhenoDesc	study_PhenoCode	study_FileURL	study_FilePortal	study_AccessDate	study_Use	study_Controller	study_Contact	study_Restrictions	study_inHouseData	study_Ancestry	study_Gender	study_PhasePanel	study_PhaseSoftware	study_ImputePanel	study_ImputeSoftware	study_Array	study_Notes	stats_TraitType	stats_Model	stats_TotalN	stats_CaseN	stats_ControlN	stats_GCMethod	stats_GCValue	stats_Notes	col_CHR	col_POS	col_SNP	col_EffectAllele	col_OtherAllele	col_BETA	col_SE	col_OR	col_ORL95	col_ORU95	col_Z	col_P	col_N	col_CaseN	col_ControlN	col_EAF	col_OAF	col_INFO	col_Direction	col_Notes	path_sumStats	path_readMe	path_pdf	cleansumstats_metafile_date	cleansumstats_metafile_user	cleansumstats_version
2021-01-20	2123	2	2020	asdad	asdad	asdad	asdad	2020_01_20	open	www.biorxiv.org/content/10.1101/240911v1	Andrew.Schork@regionh.dk	Can only be used when the planets are aligned	oASTRO	MARS	missing	starbucks	Cat1.5	ikea	Dog9.0	the best one	No, I forgot take notes in class	Stuff	Jepp	25	2	23	astrology	3.50	Notes about stats	chr	pos	snp	a1	a2	b	se	or	orl95	oru95	z	pval	n	case_n	control_n	eaf	oaf	info	dir	notes	missing	readme.md	missing	2021-01-20	jesgad	0.1-beta
EOF

tr '\t' '\n' < ./expected_result > ./expected_result_linebreak

_run_script

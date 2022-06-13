#!/usr/bin/env bash

set -euo pipefail

test_script="flip_direction_on_clean"
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
  curr_case="${1}"
}

function _check_results {
  obs=$1
  exp=$2
  if ! diff ${obs} ${exp} &> ./difference; then
    echo "- [FAIL] ${curr_case}"
    cat ./difference 
    exit 1
  fi

}

function _run_script {

  "${test_script}.sh" input.gz observed-output.gz

  _check_results <(zcat observed-output.gz) <(zcat expected-output.gz)

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# test simple case

_setup "test flip of a basic use case"

# OR is totally made up by copying directly from B
cat <<EOF | gzip -c > input.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	OR	B	Z	EAF_1KG
10	102814179	1873	rs284858	T	C	0.1592	0.0132	0.0187	0.0187	1.41667	0.6
10	10574522	1582	rs2025468	T	C	0.5398	0.0165	0.0101	0.0101	0.612121	0.33
10	106371703	1151	rs1409409	C	A	0.7713	0.0171	-0.005	-0.005	-0.292398	0.13
10	107148593	1013	rs12781860	A	C	0.9482	0.0241	0.0016	0.0016	0.06639	1
10	113128849	1129	rs1362943	G	A	0.187	0.0136	-0.018	-0.018	-1.32353	0.95
10	118368257	1008	rs12767500	C	T	0.09108	0.0308	-0.052	-0.052	-1.68831	0
10	119204075	232	rs10886419	T	C	0.784	0.0141	0.0039	0.0039	0.276596	0.53
10	123360107	534	rs9423334	G	A	0.6824	0.0268	-0.011	-0.011	-0.410448	0.08
10	123446414	2251	rs4980192	G	A	0.5813	0.0241	0.0133	0.0133	0.551867	0
EOF

cat <<EOF | gzip -c > expected-output.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	OR	B	Z	EAF_1KG
10	102814179	1873	rs284858	C	T	0.1592	0.0132	53.4759	-0.0187	-1.41667	0.4
10	10574522	1582	rs2025468	C	T	0.5398	0.0165	99.0099	-0.0101	-0.612121	0.67
10	106371703	1151	rs1409409	A	C	0.7713	0.0171	-200	0.005	0.292398	0.87
10	107148593	1013	rs12781860	C	A	0.9482	0.0241	625	-0.0016	-0.06639	0
10	113128849	1129	rs1362943	A	G	0.187	0.0136	-55.5556	0.018	1.32353	0.05
10	118368257	1008	rs12767500	T	C	0.09108	0.0308	-19.2308	0.052	1.68831	1
10	119204075	232	rs10886419	C	T	0.784	0.0141	256.41	-0.0039	-0.276596	0.47
10	123360107	534	rs9423334	A	G	0.6824	0.0268	-90.9091	0.011	0.410448	0.92
10	123446414	2251	rs4980192	A	G	0.5813	0.0241	75.188	-0.0133	-0.551867	1
EOF

_run_script

#---------------------------------------------------------------------------------
# test with added 1kg pops
_setup "test with added 1kg pops"

cat <<EOF | gzip -c > input.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	B	Z	EAF_1KG	EAS	EUR	AFR	AMR	SAS
10	102814179	1873	rs284858	T	C	0.1592	0.0132	0.0187	1.41667	0.6	0.6	0.41	0.46	0.42	0.36
10	10574522	1582	rs2025468	T	C	0.5398	0.0165	0.0101	0.612121	0.33	0.33	0.18	0.24	0.11	0.25
10	106371703	1151	rs1409409	C	A	0.7713	0.0171	-0.005	-0.292398	0.13	0.13	0.16	0.28	0.21	0.09
10	107148593	1013	rs12781860	A	C	0.9482	0.0241	0.0016	0.06639	1	1	0.92	1	0.94	0.99
10	113128849	1129	rs1362943	G	A	0.187	0.0136	-0.018	-1.32353	0.95	0.95	0.72	0.79	0.83	0.89
10	118368257	1008	rs12767500	C	T	0.09108	0.0308	-0.052	-1.68831	0	0	0.05	0.04	0.01	0.06
10	119204075	232	rs10886419	T	C	0.784	0.0141	0.0039	0.276596	0.53	0.53	0.28	0.48	0.25	0.24
10	123360107	534	rs9423334	G	A	0.6824	0.0268	-0.011	-0.410448	0.08	0.08	0.08	0.09	0.07	0.11
10	123446414	2251	rs4980192	G	A	0.5813	0.0241	0.0133	0.551867	0	0	0.09	0.02	0.06	0.01
EOF

cat <<EOF | gzip -c > expected-output.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	B	Z	EAF_1KG	EAS	EUR	AFR	AMR	SAS
10	102814179	1873	rs284858	C	T	0.1592	0.0132	-0.0187	-1.41667	0.4	0.4	0.59	0.54	0.58	0.64
10	10574522	1582	rs2025468	C	T	0.5398	0.0165	-0.0101	-0.612121	0.67	0.67	0.82	0.76	0.89	0.75
10	106371703	1151	rs1409409	A	C	0.7713	0.0171	0.005	0.292398	0.87	0.87	0.84	0.72	0.79	0.91
10	107148593	1013	rs12781860	C	A	0.9482	0.0241	-0.0016	-0.06639	0	0	0.08	0	0.06	0.01
10	113128849	1129	rs1362943	A	G	0.187	0.0136	0.018	1.32353	0.05	0.05	0.28	0.21	0.17	0.11
10	118368257	1008	rs12767500	T	C	0.09108	0.0308	0.052	1.68831	1	1	0.95	0.96	0.99	0.94
10	119204075	232	rs10886419	C	T	0.784	0.0141	-0.0039	-0.276596	0.47	0.47	0.72	0.52	0.75	0.76
10	123360107	534	rs9423334	A	G	0.6824	0.0268	0.011	0.410448	0.92	0.92	0.92	0.91	0.93	0.89
10	123446414	2251	rs4980192	A	G	0.5813	0.0241	-0.0133	-0.551867	1	1	0.91	0.98	0.94	0.99
EOF

_run_script

#---------------------------------------------------------------------------------
# test with missing flip types
_setup "test with missing flip types"

cat <<EOF | gzip -c > input.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE
10	102814179	1873	rs284858	T	C	0.1592	0.0132
10	10574522	1582	rs2025468	T	C	0.5398	0.0165
10	106371703	1151	rs1409409	C	A	0.7713	0.0171
10	107148593	1013	rs12781860	A	C	0.9482	0.0241
10	113128849	1129	rs1362943	G	A	0.187	0.0136
10	118368257	1008	rs12767500	C	T	0.09108	0.0308
10	119204075	232	rs10886419	T	C	0.784	0.0141
10	123360107	534	rs9423334	G	A	0.6824	0.0268
10	123446414	2251	rs4980192	G	A	0.5813	0.0241
EOF

cat <<EOF | gzip -c > expected-output.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE
10	102814179	1873	rs284858	C	T	0.1592	0.0132
10	10574522	1582	rs2025468	C	T	0.5398	0.0165
10	106371703	1151	rs1409409	A	C	0.7713	0.0171
10	107148593	1013	rs12781860	C	A	0.9482	0.0241
10	113128849	1129	rs1362943	A	G	0.187	0.0136
10	118368257	1008	rs12767500	T	C	0.09108	0.0308
10	119204075	232	rs10886419	C	T	0.784	0.0141
10	123360107	534	rs9423334	A	G	0.6824	0.0268
10	123446414	2251	rs4980192	A	G	0.5813	0.0241
EOF

_run_script

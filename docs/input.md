# Input
All information to run each sumstat file should be defined in a metafile.


### Requirements
All requirements are specified in the file `assets/schemas/raw-metadata.yaml`, but here we will go through the thinking behind how we selected them.

## Minimum requirements
It is possible to run the pipeline with just a few fields in the metafile. This is useful if you just want to process the data without the intention of adding it to a library, or if you have your own library system.

The absolute minimum requirements are:
- "path_sumStats"
- "stats_Model"
- "col_SNP" or "col_CHR" and "col_POS"
- "col_EffectAllele"
- anyOf:
  - "col_BETA"
  - "col_SE"
  - "col_Z"
  - "col_P"
  - "col_OR"
  - "col_ORL95"
  - "col_ORU95"
  - "col_N"
  - "col_CaseN"
  - "col_ControlN"
  - "col_EAF"
  - "col_OAF"
  - "col_INFO"
  - "col_Direction"

Dependend fields:
- col_P, if stats_neglog10P

## Minimum requirements for inclusion in a sumstat library
If the library switch in the config is activated, then more fields will be required:

The minimum requirements to organize a library are:
- "cleansumstats_version"
- "cleansumstats_metafile_user"
- "cleansumstats_metafile_date"
- "path_sumStats"
- "study_Title"
- "study_PMID"
- "study_Year"
- "study_PhenoDesc"
- "study_PhenoCode"
- "study_AccessDate"
- "study_Use"
- "study_Ancestry"
- "study_Gender"
- "stats_TraitType"
- "stats_TotalN"
- "stats_Model"
- "col_EffectAllele"

As well as
- "col_SNP" or "col_CHR" and "col_POS"
- anyOf:
  - "col_BETA"
  - "col_SE"
  - "col_Z"
  - "col_P"
  - "col_OR"
  - "col_ORL95"
  - "col_ORU95"
  - "col_N"
  - "col_CaseN"
  - "col_ControlN"
  - "col_EAF"
  - "col_OAF"
  - "col_INFO"
  - "col_Direction"

Dependend fields:
- col_P, if stats_neglog10P


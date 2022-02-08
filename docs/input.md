# Input
All information to run each sumstat file should be defined in a metafile.

## Metadata

### Types
The different types of fields are broadly categoriezed with a prefix:
`path_` for filenames 
`study_` for study/sumstat-specific information
`stat_` for information about the statistical model 
`col_` for the name of each stats column in the sumstat file

There are three note fields: `study_Notes`, `stats_Notes` and `col_Notes`. `col_Notes` would be a good place for variant specific notes or explaining odd column names.

There is no `path_` support for relative links in the metadata file, which means all files have to be in the same folder. However, you can provide paths to associated files `-p path/to/folder1,path/to/folder2`

### Requirements
All requirements are specified in the file `assets/schemas/raw-metadata.yaml`, but here we will go through the thinking behind how we selected them.

## Minimum requirements (default)
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
  - "col_StudyN"

Dependend fields:
- col_P, if stats_neglog10P

## Minimum requirements for inclusion in a sumstat library
If the library switch is activated, by addiing the field and value:
- "cleansumstats_metafile_kind: library"

then these additional minimum fields will be required:
- "cleansumstats_version"
- "cleansumstats_metafile_user"
- "cleansumstats_metafile_date"
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


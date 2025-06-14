# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.12.1] - 2025-06-11

### Fixed
- Fixed Singularity execution to include proper nextflow parameters and bind mounts
- Set Singularity home directory to output directory to ensure .nextflow directory is created where cleanup expects it
- Removed --no-eval flag for compatibility with older Singularity versions
- Fixed permission denied error when running main.nf by adding execute permissions
- Added directory existence check in cleanup function to prevent rm warnings
- Addresses GitHub issue #441

## [1.12.0] - 2025-05-30

### Added
- Enhanced test infrastructure with session-based logging for organized test execution
- Comprehensive thread limiting and resource optimization for containerized environments
- Specific resource configurations for DbSNP reference generation processes
- System-level thread limiting environment variables (OMP_NUM_THREADS, MKL_NUM_THREADS, etc.)
- Aggressive JVM thread limiting options to prevent thread exhaustion

### Changed
- Migrated from parallel to sequential test execution for improved reliability
- Optimized test timeouts and resource allocation (liftover: 3GB memory, 15min timeout)
- Moved parallel test infrastructure to deprecated-parallel-features directory
- Updated convert_neglogP unit test expected values to use scientific notation format

### Fixed
- Thread exhaustion issues in DbSNP reference generation tests (regression_197, regression_201)
- Test execution reliability achieving 100% test success rate (20/20 e2e tests pass)
- Resource conflicts and hanging tests in containerized environments
- Convert_neglogP unit test formatting to match updated scientific notation output

## [1.11.2] - 2025-05-27

### Changed
- precision of pvalue output to 5 digits from 15 digits

## [1.11.1] - 2025-05-27

### Fixed
- Fixed truncation issue for -log10 conversions of pvalues

## [1.11.0] - 2025-02-10

### Added
- New chrpos allele duplicate filter to improve data quality

## [1.10.0] - 2025-02-07

### Added
- Multi-architecture support for AMD64 and ARM64 systems
- Architecture-specific Docker image tags (e.g., 1.3.0-amd64, 1.3.0-arm64)
- Improved Docker build system using buildx for multi-arch builds

### Changed
- Updated base images to latest stable versions
- Switched to Ubuntu user from nextflow user in containers
- Improved Python package management using virtual environments
- Updated Nextflow to version 24.10.4

### Fixed
- CrossMap.py installation and path issues
- Various Docker build and deployment improvements

## [1.9.0] - 2024-09-11
### Changed
-  1kgp reference to latest release

### Added
-  New terminal ASCII logo

## [1.8.2] - 2024-06-11
### Added
-  New options to run cleansumstats.sh using test, utest or etest, which mounts and selects correct image using image specifiers in the runscript.

### Changed
- Image from being hardcoded to be set by the specifier -j

## [1.8.1] - 2024-06-11
### Added
-  New options to run cleansumstats.sh using docker images, both locally built or pulled from dockerhub

### Changed
-  Names of dbsnp reference files to sound more general and representative. The previous names could be misleading. 
-  Tests to align with the new dbsnp reference file names. All tests ok.

## [1.8.0] - 2024-05-02
### Fixed
- Reporting of variants not possible to map, which was previously always returned empty.

### Changed
- Removed the duplicated chrpos filter before dbsnp mapping
- Removed the duplicated chrpos filter after dbsnp mapping

### Added
- e2e test for previously missing variant, due to indels in input sumstat.
- More fast example options using -e 1 or -e 2, etc. 

## [1.7.1] - 2024-04-17
### Changed
- New default for raw metafile, which now forwarded to the raw folder in output. If the other raw files are to be forwarded, then it has to be set in the nextflow config file. 

## [1.7.0] - 2024-01-26
### Changed
- Updated the dbsnp reference in the README.md

### Added
- New support for ncbi chromosomes in the prepare dbsnp workflow
- Additional forwarding of stats to cleaned metadata

## [1.6.8] - 2024-01-21
### Fixed
- updated singularity home by also exporting apptainer home

## [1.6.7] - 2023-11-23
### Fixed
- cleaned metadata output. It now only give caseN or controlN if they are actually present in header of the output sumstat file.

### Added
- unit test for cleaned metadata output

## [1.6.6] - 2023-08-26
### Added
- varinat specific EAF to be inferred from AF and N from Case and Control 

## [1.6.5] - 2023-08-23
### Added
- Case and Control AF now possible to forward using metafile. They will be subjected to all flipping functions.

## [1.6.4] - 2023-08-07
### Added
- post-process option to flip alleles in respect to MAF, using the argument "maf". 

## [1.6.3] - 2023-05-22
### Added
- Docs about how to add an extra field using variant information

## [1.6.2] - 2023-04-13
### Fixed
- Fixed bug when chr:pos is only present in Markername. 

## [1.6.1] - 2023-03-02
### Fixed
- Permission settings on pipeline_info output. Now user, group and other have read and write permissions for all files in that folder.

## [1.6.0] - 2023-01-12
### Fixed
- The flip allele issue, originating from sumstat-tools. The fix is supported with regression and unit tests. This fix required an update of the dockerimage.

## [1.5.4] - 2022-12-15
### Added
- Citation file in preparation for public release.

## [1.5.3] - 2022-09-13
### Added
- Minimac4 as an option for the conversion old to new metadata tool.

## [1.5.2] - 2022-08-19
### Fixed
- Sumstats lacking available ancestry to not throw an error

## [1.5.1] - 2022-08-12
### Added
- Possibility to use logP pvalues. stat_neglogP is not a required field anymore.

## [1.5.0] - 2022-06-30
### Added
- Script that converts metadata files into a delimiter separated table, where:
  - Each metadata field is a column
  - Each row is a single metadata file

## [1.4.2] - 2022-07-04
### Changed
-  Raw input as output no longer default. Can be set in nextflow.config

## [1.4.1] - 2022-06-27
### Fixed
- The issue for when ORs are 0, and added a more explicit modification of ORU and ORL

## [1.4.0] - 2022-06-22
### Fixed
- 1000G added allelefrequencies are now flipped correctly. To fix this, there was a substantial rewrite of the stats subworkflow, which has been simplified, with increased performance as well.

## [1.3.12] - 2022-06-20
### Changed
- .nextflow to only be available in --dev mode, to save space in output

## [1.3.11] - 2022-06-16
### Fixed
- clean2vcf.sh bug, not recognizing input ref and alt col numbers

## [1.3.10] - 2022-06-15
### Changed
- The metadata field `study_PhenoCode` now supports `EFO` and `MONDO` codes

## [1.3.9] - 2022-06-14
### Fixed
- EffectAllele and OtherAllele to also be flipped when flipping the effects in the post-processing cleanflipdirection.sh
- clean2vcf.sh so that the right REF allele column can be picked out after the changes to cleanflipdirection.sh
- nextflow lock files to be placed within the output directory to not cause lock file issues when running multiple local jobs

### Added
- Cleansumstats version to output metadata.

### Changed
- Removed the need to specify cleansumstats version in the input metadata file

## [1.3.8] - 2022-04-01
### Fixed
-  Vcf header to be float instead of integer for sample size to give room for the extra precision of the estimated sample sizes.

## [1.3.7] - 2022-03-24
### Fixed
-  Duplication issue for GRCh35 and GRCh36 builds

## [1.3.6] - 2022-03-17
### Fixed
-  tmp is now automatically created if missing by cleansumstats.sh

## [1.3.5] - 2022-03-14
### Fixed
-  Switched names for two files in details.

## [1.3.4] - 2022-03-10
### Fixed
-  The clean2vcf to use the correct meta info in the vcf for alternative allele requency based sumstats
-  The clean2vcf to use both the population specific AF and 1KG in the format field

## [1.3.3] - 2022-03-09
### Fixed
-  The run file to be run from anywhere also using the -e flag

## [1.3.2] - 2022-02-23
### Fixed
-  The path to README so that it is no longer pointing to the pdf

## [1.3.1] - 2022-02-22
### Added
-  New allowed values e.g., reference panels in the metafile schema

## [1.3.0] - 2022-02-08
### Added
- New post-processing adding all 5 major pops from 1kgp
- New post-processing flipping allele direction of effects
- More options regarding directing and repressing output using nextflow.config
- Explanation of how to treat .csv input in troubleshooting
- New instructions in the README.md to set a more flexible write access to the user created `tmp/` folder
- Support for extra paths to search for files in the metafile using `-p path1,path2`
- Support for variant specific information of number of metastudies: `col_StudyN`
- Support for two metafile minimum requiriments options, default and library
- New user options to set tmp and workdirs -b -w
- New user option to set dev mode -l
- Automatic cleanup of workdir when not in dev move

### Changed
- DSL-1 converted to DSL-2
- Updated nextflow in Dockerfile to nextflow-21.12.1-edge-all
- Improved `docs/`, but still work to be done

### Fixed
- AF information has now support for NA
- It is now possible to run from anywhere, not only from within the clensumstats repo
- DIRECTION is now skipped by the awk numeric test
- General support for NA in r-stat-c-streamer

## [1.2.0] - 2021-12-08
### Added
- Post-process script that converts from the present output format to a vcf file, mathing column names to https://github.com/MRCIEU/gwas2vcf
- New file in the details folder explaining the source of each output column
- New post-process section in docs that is linked to from README.md

## [1.1.10] - 2021-11-22
### Fixed
- Allele frequency was not sent correctly to r-stats-c-streamer, which returned strange results for the inferred N.

## [1.1.9] - 2021-11-04
### Fixed
- When no otherAllele was specified, it resulted in no rows from the allele correction process. It all was caused by the shift from the old metadata reader to the new groovy version. In the end resulting in that the path was never taken through the process for when only effect allele exists.

## [1.1.8] - 2021-11-02
### Fixed
- A previous fix of the advanced chromosome reformatting introduced a bug. The main problem was that we tried to feed two special functions to sumstats-tools, while it can only take one. The solution was to do the manipulation in two steps.

## [1.1.7] - 2021-10-29
### Fixed
- Mounting system /tmp on image /tmp to not run out of image memory

## [1.1.6] - 2021-10-29
### Fixed
- Giving no `col_*` fields in the metadata file is accepted as valid

## [1.1.5] - 2021-10-29
### Fixed
- Providing `study_includedCohorts` in the metadata fails with YAML deserialization error
- Pipeline version output by nextflow does not reflect the actual version in `VERSION`

## [1.1.3] - 2021-10-28
### Changed
- Updated cleansumstats.sh to follow dry principle for the nextflow call
- Remove artifatcs in README.md

## [1.1.2] - 2021-10-28
### Changed
- Updated output of cleansumstats.sh -h in README.md

## [1.1.1] - 2021-10-28
### Added
- Version flag -v to cleansumstats.sh
- Documentation about versioning to docs/developers.md

## [1.1.0] - 2021-10-28
### Added
- Variable and path test to cleansumstats.sh
- Prepare-1kgp to cleansumstats.sh
- Prepare-dbsnp to cleansumstats.sh

### Changed
- Moved almost all introduction content to outout docs to make README.md more readable
- README.md to match the new cleansumstats.sh

## [1.0.2] - 2021-10-27
### Changed
- Default path for cleansumstats.sh to match with README.md

## [1.0.1] - 2021-10-26
### Fixed
- Set default testoption=false, which was missing for cleansumstats.sh

## [1.0.0] - 2021-10-20
### Added

Major updates from alpha version

Many new features including:

- A more complete stat conversion suite, https://github.com/pappewaio/r-stats-c-streamer
- 1000 genomes AF added for 5 main populations
- New metafile format in .yaml
- Multi-allelics allowed
- dbsnp prefiltered on duplicated chr:pos pairs and indels
- three path chr:pos mapping
- MISSING: a complete OR stat conversions suite

Technical features:

- Docker builder
- Singularity builder
- Example data
- Better documentation
- test suite (almost complete)

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2021-12-08
### Added
- Add post-process script that converts from the present output format to a vcf file, mathing column names to https://github.com/MRCIEU/gwas2vcf
- Add a file in the details folder explaining the source of each output column
- Add a post-process section in docs that is linked to from README.md

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
- mounting system /tmp on image /tmp to not run out of image memory

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
- Added version flag -v to cleansumstats.sh
- Added documentation about versioning to docs/developers.md

## [1.1.0] - 2021-10-28
### Added
- Added variable and path test to cleansumstats.sh
- Added prepare-1kgp to cleansumstats.sh
- Added prepare-dbsnp to cleansumstats.sh

### Changed
- Moved almost all introduction content to outout docs to make README.md more readable
- Changed README.md to match the new cleansumstats.sh

## [1.0.2] - 2021-10-27
### Changed
- Changed default path for cleansumstats.sh to match with README.md

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

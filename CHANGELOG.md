# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.3] - 2021-10-28
### Changed
 - updated cleansumstats.sh to follow dry principle for the nextflow call
 - remove artifatcs in README.md 

## [1.1.2] - 2021-10-28
### Changed
 - updated output of cleansumstats.sh -h in README.md

## [1.1.1] - 2021-10-28
### Added 
 - added version flag -v to cleansumstats.sh
 - added documentation about versioning to docs/developers.md

## [1.1.0] - 2021-10-28
### Added 
 - added variable and path test to cleansumstats.sh
 - added prepare-1kgp to cleansumstats.sh
 - added prepare-dbsnp to cleansumstats.sh

### Changed 
 - moved almost all introduction content to outout docs to make README.md more readable
 - changed README.md to match the new cleansumstats.sh 

## [Released]

## [1.0.2] - 2021-10-27
### Changed 
 - changed default path for cleansumstats.sh to match with README.md

## [1.0.1] - 2021-10-26
### Fixed 
 - set default testoption=false, which was missing for cleansumstats.sh

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


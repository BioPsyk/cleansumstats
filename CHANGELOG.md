# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Released]

## [1.0.1] - 2021-10-26
### Changed hotfix-224
 - set default testoption=false, which was missing for cleansumstats.sh

## [1.0.0] - 2021-10-20
### Added (major updates from alpha version)

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


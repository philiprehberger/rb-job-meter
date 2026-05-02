# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-05-01

### Added
- `JobMeter.job_classes` -- list every job class with at least one recorded entry; lets dashboards enumerate registered jobs without serializing the full Prometheus or JSON export

## [0.4.0] - 2026-04-15

### Added
- `JobMeter.measure(job_class, tags:, &block)` -- time a block and auto-record duration and success based on whether it raises; exceptions are re-raised after recording
- `JobMeter.tag_values(job_class, key)` -- return the unique values seen for a tag key on a job class, useful for building dashboards or driving subsequent filtered queries
- `JobMeter.clear!(job_class)` -- drop metrics and trending data for a single job class without disturbing others; returns `true` when something was cleared

### Changed
- Streamline README API section to the standard method/description table and move Usage examples for new features alongside existing ones

## [0.3.0] - 2026-04-14

### Added
- Tags support for `record` and `stats` -- attach arbitrary key-value tags to recordings and filter stats by tag values
- `JobMeter.histogram(name, buckets:)` -- bucket durations into configurable ranges and return counts per bucket
- `JobMeter.to_prometheus` -- export all recorded metrics in Prometheus text exposition format
- `JobMeter.to_json_export` -- export all metrics as a JSON string with job names, stats, and histograms

## [0.2.1] - 2026-04-08

### Changed
- Align gemspec summary with README description.

## [0.2.0] - 2026-04-04

### Added
- Time-bucketed trending stats with `.trending(job_class)` returning rolling 1m/5m/15m windows
- GitHub issue template gem version field
- Feature request "Alternatives considered" field

## [0.1.11] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.10] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.9] - 2026-03-26

### Changed
- Add Sponsor badge to README
- Fix License section format
- Sync gemspec summary with README


## [0.1.8] - 2026-03-24

### Changed
- Add Usage subsections to README for better feature discoverability

## [0.1.7] - 2026-03-24

### Fixed
- Align README one-liner with gemspec summary

## [0.1.6] - 2026-03-22

### Changed
- Expand test coverage

## [0.1.5] - 2026-03-20

### Changed
- Expand API section in README with detailed return values, percentile explanations, example output, and stats interpretation guide
- Restructure CHANGELOG to follow Keep a Changelog format

## [0.1.4] - 2026-03-19

### Changed
- Revert gemspec to single-quoted strings per RuboCop default configuration

## [0.1.3] - 2026-03-18

### Fixed
- Fix RuboCop Style/StringLiterals violations in gemspec

## [0.1.2] - 2026-03-17

### Added
- Add License badge to README
- Add bug_tracker_uri to gemspec
- Add Requirements section to README

## [0.1.0] - 2026-03-15

### Added
- Initial release
- Framework-agnostic job instrumentation
- Percentile tracking (p50, p95, p99)
- Success/failure rate per job class
- Top slowest and failing reports

[Unreleased]: https://github.com/philiprehberger/rb-job-meter/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/philiprehberger/rb-job-meter/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/philiprehberger/rb-job-meter/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/philiprehberger/rb-job-meter/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.11...v0.2.0
[0.1.11]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.10...v0.1.11
[0.1.10]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.9...v0.1.10
[0.1.9]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/philiprehberger/rb-job-meter/compare/v0.1.0...v0.1.2
[0.1.0]: https://github.com/philiprehberger/rb-job-meter/releases/tag/v0.1.0

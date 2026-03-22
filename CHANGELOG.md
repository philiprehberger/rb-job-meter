# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

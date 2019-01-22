# philiprehberger-job_meter

[![Tests](https://github.com/philiprehberger/rb-job-meter/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-job-meter/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-job_meter.svg)](https://rubygems.org/gems/philiprehberger-job_meter)
[![License](https://img.shields.io/github/license/philiprehberger/rb-job-meter)](LICENSE)

Framework-agnostic background job instrumentation and metrics

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-job_meter"
```

Or install directly:

```bash
gem install philiprehberger-job_meter
```

## Usage

```ruby
require "philiprehberger/job_meter"

# Record job executions
Philiprehberger::JobMeter.record("SendEmailJob", duration: 1.23, success: true)
Philiprehberger::JobMeter.record("SendEmailJob", duration: 0.87, success: false)
Philiprehberger::JobMeter.record("ImportCsvJob", duration: 45.6, success: true)

# Get stats for a specific job class
stats = Philiprehberger::JobMeter.stats("SendEmailJob")
# => { avg_duration: 1.05, p50_duration: 1.05, p95_duration: 1.212,
#      p99_duration: 1.2264, success_rate: 0.5, total: 2, failed: 1 }

# Find slowest jobs by average duration
Philiprehberger::JobMeter.top_slowest(5)
# => [{ job_class: "ImportCsvJob", avg_duration: 45.6, ... }, ...]

# Find jobs with highest failure rates
Philiprehberger::JobMeter.top_failing(5)
# => [{ job_class: "SendEmailJob", success_rate: 0.5, ... }, ...]

# Clear all recorded metrics
Philiprehberger::JobMeter.reset!
```

## API

| Method | Description |
|--------|-------------|
| `JobMeter.record(job_class, duration:, success:)` | Record a single job execution |
| `JobMeter.stats(job_class)` | Return a stats hash for a specific job class, or `nil` if no data recorded |
| `JobMeter.top_slowest(num = 5)` | Return an array of stats hashes ranked by slowest average duration (descending) |
| `JobMeter.top_failing(num = 5)` | Return an array of stats hashes ranked by lowest success rate (ascending) |
| `JobMeter.reset!` | Clear all recorded metrics from memory |

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `job_class` | `String` | Identifier for the job class (typically the class name) |
| `duration` | `Float` | Execution time in seconds |
| `success` | `Boolean` | Whether the job completed successfully |
| `num` | `Integer` | Maximum number of results to return (default: `5`) |

### Return values

`stats` and the ranking methods return hashes with these keys:

| Key | Type | Description |
|-----|------|-------------|
| `:avg_duration` | `Float` | Mean execution time across all recorded runs |
| `:p50_duration` | `Float` | 50th percentile (median) -- half of all runs completed faster than this value |
| `:p95_duration` | `Float` | 95th percentile -- 95% of runs completed faster; the remaining 5% are slower outliers |
| `:p99_duration` | `Float` | 99th percentile -- only 1% of runs exceeded this duration; useful for tail-latency monitoring |
| `:success_rate` | `Float` | Ratio of successful runs to total runs, from `0.0` (all failed) to `1.0` (all succeeded) |
| `:total` | `Integer` | Total number of recorded executions |
| `:failed` | `Integer` | Number of executions where `success` was `false` |
| `:job_class` | `String` | Job class identifier (only present in `top_slowest` / `top_failing` results) |

### Example output

```ruby
stats = Philiprehberger::JobMeter.stats("SendEmailJob")
# => {
#      avg_duration: 1.05,
#      p50_duration: 1.05,
#      p95_duration: 1.212,
#      p99_duration: 1.2264,
#      success_rate: 0.5,
#      total: 2,
#      failed: 1
#    }
```

### Interpreting stats

- **Capacity planning** -- Compare `avg_duration` across job classes to identify which jobs consume the most worker time and may need dedicated queues.
- **Tail-latency monitoring** -- A large gap between `p50_duration` and `p99_duration` indicates high variance. Jobs with spiky p99 values are candidates for timeout tuning or retry-backoff adjustments.
- **Failure alerting** -- Track `success_rate` over time to detect regressions. A rate dropping below a threshold (e.g., `0.95`) can trigger alerts before failures cascade.
- **Ranking hotspots** -- Use `top_slowest` and `top_failing` to surface the most problematic jobs without inspecting every class individually.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT

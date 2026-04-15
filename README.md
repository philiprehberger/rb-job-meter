# philiprehberger-job_meter

[![Tests](https://github.com/philiprehberger/rb-job-meter/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-job-meter/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-job_meter.svg)](https://rubygems.org/gems/philiprehberger-job_meter)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-job-meter)](https://github.com/philiprehberger/rb-job-meter/commits/main)

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

Record job executions anywhere in your application:

```ruby
require "philiprehberger/job_meter"

Philiprehberger::JobMeter.record("SendEmailJob", duration: 1.23, success: true)
Philiprehberger::JobMeter.record("SendEmailJob", duration: 0.87, success: false)
Philiprehberger::JobMeter.record("ImportCsvJob", duration: 45.6, success: true)
```

### Querying Stats

Retrieve computed metrics for a specific job class. Returns `nil` if no data has been recorded for that class.

```ruby
stats = Philiprehberger::JobMeter.stats("SendEmailJob")
# => { avg_duration: 1.05, p50_duration: 1.05, p95_duration: 1.212,
#      p99_duration: 1.2264, success_rate: 0.5, total: 2, failed: 1 }
```

### Top Slowest and Failing

Surface the most problematic jobs without inspecting every class individually. Both methods accept an optional limit (default: 5).

```ruby
# Ranked by slowest average duration (descending)
Philiprehberger::JobMeter.top_slowest(5)
# => [{ job_class: "ImportCsvJob", avg_duration: 45.6, ... }, ...]

# Ranked by lowest success rate (ascending)
Philiprehberger::JobMeter.top_failing(5)
# => [{ job_class: "SendEmailJob", success_rate: 0.5, ... }, ...]
```

### Tags

Attach arbitrary key-value metadata to each recording, then filter stats by tag values:

```ruby
Philiprehberger::JobMeter.record("SendEmailJob", duration: 1.2, success: true, tags: { queue: "high", env: "production" })
Philiprehberger::JobMeter.record("SendEmailJob", duration: 0.8, success: true, tags: { queue: "low", env: "staging" })
Philiprehberger::JobMeter.record("SendEmailJob", duration: 2.1, success: false, tags: { queue: "high", env: "production" })

# Filter stats to only "high" queue in production
stats = Philiprehberger::JobMeter.stats("SendEmailJob", tags: { queue: "high", env: "production" })
# => { avg_duration: 1.65, ..., total: 2, failed: 1 }

# Without tags filter, returns stats for all recordings
stats = Philiprehberger::JobMeter.stats("SendEmailJob")
# => { ..., total: 3 }
```

### Histogram

Bucket durations into configurable ranges and get counts per bucket:

```ruby
Philiprehberger::JobMeter.histogram("SendEmailJob", buckets: [0.1, 0.5, 1.0, 5.0])
# => { "0-0.1" => 0, "0.1-0.5" => 0, "0.5-1.0" => 1, "1.0-5.0" => 2, "5.0+" => 0 }
```

### Prometheus Export

Export all recorded metrics in Prometheus text exposition format:

```ruby
puts Philiprehberger::JobMeter.to_prometheus
# # HELP job_duration_seconds Duration of job executions
# # TYPE job_duration_seconds gauge
# job_duration_seconds_avg{job_class="SendEmailJob"} 1.3666666666666667
# job_duration_seconds_p50{job_class="SendEmailJob"} 1.2
# ...
# job_executions_total{job_class="SendEmailJob"} 3
# job_failures_total{job_class="SendEmailJob"} 1
# job_success_rate{job_class="SendEmailJob"} 0.6666666666666666
```

### JSON Export

Export all metrics as a JSON string:

```ruby
json = Philiprehberger::JobMeter.to_json_export
# => '{"jobs":[{"job_class":"SendEmailJob","stats":{"avg_duration":1.37,...}}]}'
```

### Trending Stats

```ruby
require "philiprehberger/job_meter"

Philiprehberger::JobMeter.record("SendEmailJob", duration: 0.45, success: true)

trending = Philiprehberger::JobMeter.trending("SendEmailJob")
trending[:last_1m]   # => { avg_duration: 0.45, success_rate: 1.0, total: 1, failed: 0 }
trending[:last_5m]   # => { avg_duration: 0.45, success_rate: 1.0, total: 1, failed: 0 }
trending[:last_15m]  # => { avg_duration: 0.45, success_rate: 1.0, total: 1, failed: 0 }
```

### Reset

Clear all recorded metrics from memory. Useful between test runs or when rotating collection windows.

```ruby
Philiprehberger::JobMeter.reset!
```

## API

| Method | Description |
|--------|-------------|
| `JobMeter.record(job_class, duration:, success:, tags: {})` | Record a single job execution with optional tags |
| `JobMeter.stats(job_class, tags: {})` | Return a stats hash, optionally filtered by tags. Returns `nil` if no matching data |
| `JobMeter.histogram(job_class, buckets:)` | Return a hash mapping bucket ranges to duration counts |
| `JobMeter.top_slowest(num = 5)` | Return an array of stats hashes ranked by slowest average duration (descending) |
| `JobMeter.top_failing(num = 5)` | Return an array of stats hashes ranked by lowest success rate (ascending) |
| `JobMeter.trending(job_class)` | Returns rolling stats for the last 1m, 5m, and 15m windows |
| `JobMeter.to_prometheus` | Export all metrics in Prometheus text exposition format |
| `JobMeter.to_json_export` | Export all metrics as a JSON string |
| `JobMeter.reset!` | Clear all recorded metrics from memory |

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `job_class` | `String` | Identifier for the job class (typically the class name) |
| `duration` | `Float` | Execution time in seconds |
| `success` | `Boolean` | Whether the job completed successfully |
| `tags` | `Hash` | Optional key-value metadata to attach to a recording or filter stats (default: `{}`) |
| `buckets` | `Array<Float>` | Bucket boundaries for histogram (e.g. `[0.1, 0.5, 1.0, 5.0]`) |
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

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-job-meter)

🐛 [Report issues](https://github.com/philiprehberger/rb-job-meter/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-job-meter/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)

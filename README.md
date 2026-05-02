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

```ruby
require "philiprehberger/job_meter"

Philiprehberger::JobMeter.record("SendEmailJob", duration: 1.23, success: true)
Philiprehberger::JobMeter.record("SendEmailJob", duration: 0.87, success: false)
Philiprehberger::JobMeter.record("ImportCsvJob", duration: 45.6, success: true)
```

### Measure a block

Wrap work in a block and `JobMeter` will time it and record success or failure based on whether the block raises:

```ruby
require "philiprehberger/job_meter"

result = Philiprehberger::JobMeter.measure("SendEmailJob", tags: { queue: "default" }) do
  send_email!
end
# => block return value; duration and success are recorded automatically
```

Exceptions are re-raised after the failure is recorded.

### Querying stats

Retrieve computed metrics for a specific job class. Returns `nil` if no data has been recorded for that class.

```ruby
stats = Philiprehberger::JobMeter.stats("SendEmailJob")
# => { avg_duration: 1.05, p50_duration: 1.05, p95_duration: 1.212,
#      p99_duration: 1.2264, success_rate: 0.5, total: 2, failed: 1 }
```

### Top slowest and failing

Both methods accept an optional limit (default: 5).

```ruby
Philiprehberger::JobMeter.top_slowest(5)
# => [{ job_class: "ImportCsvJob", avg_duration: 45.6, ... }, ...]

Philiprehberger::JobMeter.top_failing(5)
# => [{ job_class: "SendEmailJob", success_rate: 0.5, ... }, ...]
```

### Tags

Attach arbitrary key-value metadata to each recording, then filter stats by tag values:

```ruby
require "philiprehberger/job_meter"

Philiprehberger::JobMeter.record("SendEmailJob", duration: 1.2, success: true, tags: { queue: "high", env: "production" })
Philiprehberger::JobMeter.record("SendEmailJob", duration: 0.8, success: true, tags: { queue: "low", env: "staging" })
Philiprehberger::JobMeter.record("SendEmailJob", duration: 2.1, success: false, tags: { queue: "high", env: "production" })

stats = Philiprehberger::JobMeter.stats("SendEmailJob", tags: { queue: "high", env: "production" })
# => { avg_duration: 1.65, ..., total: 2, failed: 1 }
```

### Tag values

List all distinct values recorded for a given tag key. Useful for building dashboards or driving subsequent filtered queries:

```ruby
Philiprehberger::JobMeter.tag_values("SendEmailJob", :queue)
# => ["high", "low"]
```

### Listing job classes

Enumerate every job class with at least one recorded entry — useful for dashboards that need to iterate without parsing the full export:

```ruby
Philiprehberger::JobMeter.job_classes
# => ["SendEmailJob", "ImportCsvJob"]
```

### Histogram

Bucket durations into configurable ranges and get counts per bucket:

```ruby
Philiprehberger::JobMeter.histogram("SendEmailJob", buckets: [0.1, 0.5, 1.0, 5.0])
# => { "0-0.1" => 0, "0.1-0.5" => 0, "0.5-1.0" => 1, "1.0-5.0" => 2, "5.0+" => 0 }
```

### Prometheus export

```ruby
puts Philiprehberger::JobMeter.to_prometheus
# # HELP job_duration_seconds Duration of job executions
# # TYPE job_duration_seconds gauge
# job_duration_seconds_avg{job_class="SendEmailJob"} 1.3666666666666667
# ...
```

### JSON export

```ruby
json = Philiprehberger::JobMeter.to_json_export
# => '{"jobs":[{"job_class":"SendEmailJob","stats":{"avg_duration":1.37,...}}]}'
```

### Trending stats

```ruby
require "philiprehberger/job_meter"

Philiprehberger::JobMeter.record("SendEmailJob", duration: 0.45, success: true)

trending = Philiprehberger::JobMeter.trending("SendEmailJob")
trending[:last_1m]   # => { avg_duration: 0.45, success_rate: 1.0, total: 1, failed: 0 }
trending[:last_5m]   # => { avg_duration: 0.45, success_rate: 1.0, total: 1, failed: 0 }
trending[:last_15m]  # => { avg_duration: 0.45, success_rate: 1.0, total: 1, failed: 0 }
```

### Clearing a single job class

Drop all metrics and trending data for a single job class without disturbing others:

```ruby
Philiprehberger::JobMeter.clear!("SendEmailJob")
# => true (or false when the job class was not tracked)
```

### Reset

Clear all recorded metrics from memory:

```ruby
Philiprehberger::JobMeter.reset!
```

## API

| Method | Description |
|--------|-------------|
| `JobMeter.record(job_class, duration:, success:, tags: {})` | Record a single job execution with optional tags |
| `JobMeter.measure(job_class, tags: {}, &block)` | Run a block, timing it and recording success/failure automatically; re-raises |
| `JobMeter.stats(job_class, tags: {})` | Return a stats hash, optionally filtered by tags; `nil` if no matching data |
| `JobMeter.histogram(job_class, buckets:)` | Return a hash mapping bucket ranges to duration counts |
| `JobMeter.tag_values(job_class, key)` | Return an array of unique values seen for a tag key on a job class |
| `JobMeter.job_classes` | Return every job class with at least one recorded entry |
| `JobMeter.top_slowest(num = 5)` | Return stats hashes ranked by slowest average duration (descending) |
| `JobMeter.top_failing(num = 5)` | Return stats hashes ranked by lowest success rate (ascending) |
| `JobMeter.trending(job_class)` | Return rolling stats for the last 1m, 5m, and 15m windows |
| `JobMeter.to_prometheus` | Export all metrics in Prometheus text exposition format |
| `JobMeter.to_json_export` | Export all metrics as a JSON string |
| `JobMeter.clear!(job_class)` | Remove metrics for a single job class; returns `true` if cleared, `false` otherwise |
| `JobMeter.reset!` | Clear all recorded metrics from memory |

Stats hashes contain the following keys:

| Key | Type | Description |
|-----|------|-------------|
| `:avg_duration` | `Float` | Mean execution time |
| `:p50_duration` | `Float` | 50th percentile (median) |
| `:p95_duration` | `Float` | 95th percentile |
| `:p99_duration` | `Float` | 99th percentile |
| `:success_rate` | `Float` | Ratio of successful runs, `0.0` to `1.0` |
| `:total` | `Integer` | Total number of recorded executions |
| `:failed` | `Integer` | Number of executions where `success` was `false` |
| `:job_class` | `String` | Job class identifier (present only in `top_slowest` / `top_failing` results) |

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

# philiprehberger-job_meter

[![Gem Version](https://badge.fury.io/rb/philiprehberger-job_meter.svg)](https://rubygems.org/gems/philiprehberger-job_meter)
[![CI](https://github.com/philiprehberger/rb-job-meter/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-job-meter/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/philiprehberger/rb-job-meter)](LICENSE)

Framework-agnostic background job instrumentation and metrics for Ruby.

Record execution duration and success/failure for any background job system, compute percentiles (p50, p95, p99), and identify your slowest or most-failing job classes.

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem 'philiprehberger-job_meter'
```

Or install directly:

```sh
gem install philiprehberger-job_meter
```

## Usage

```ruby
require 'philiprehberger/job_meter'

# Record job executions
Philiprehberger::JobMeter.record('SendEmailJob', duration: 1.23, success: true)
Philiprehberger::JobMeter.record('SendEmailJob', duration: 0.87, success: false)
Philiprehberger::JobMeter.record('ImportCsvJob', duration: 45.6, success: true)

# Get stats for a specific job class
stats = Philiprehberger::JobMeter.stats('SendEmailJob')
# => { avg_duration: 1.05, p50_duration: ..., p95_duration: ...,
#      p99_duration: ..., success_rate: 0.5, total: 2, failed: 1 }

# Find slowest jobs by average duration
Philiprehberger::JobMeter.top_slowest(5)
# => [{ job_class: 'ImportCsvJob', avg_duration: 45.6, ... }, ...]

# Find jobs with highest failure rates
Philiprehberger::JobMeter.top_failing(5)
# => [{ job_class: 'SendEmailJob', success_rate: 0.5, ... }, ...]

# Clear all recorded metrics
Philiprehberger::JobMeter.reset!
```

## API

### `JobMeter.record(job_class, duration:, success:)`

Record a single job execution. `duration` is in seconds (Float). `success` is a boolean.

### `JobMeter.stats(job_class)`

Returns a hash with `:avg_duration`, `:p50_duration`, `:p95_duration`, `:p99_duration`, `:success_rate`, `:total`, and `:failed`. Returns `nil` if the job class has no recorded data.

### `JobMeter.top_slowest(num = 5)`

Returns an array of hashes for the slowest job classes by average duration, sorted descending.

### `JobMeter.top_failing(num = 5)`

Returns an array of hashes for job classes with the lowest success rate, sorted ascending.

### `JobMeter.reset!`

Clears all recorded metrics.

## Development

```sh
bundle install
bundle exec rake spec
bundle exec rake rubocop
```

## License

Released under the [MIT License](LICENSE).

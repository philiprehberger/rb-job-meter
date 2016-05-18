# frozen_string_literal: true

require_relative 'lib/philiprehberger/job_meter/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-job_meter'
  spec.version = Philiprehberger::JobMeter::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Framework-agnostic background job instrumentation and metrics'
  spec.description = 'Thread-safe instrumentation for background jobs. Record execution ' \
                     'duration and success/failure, compute percentiles (p50, p95, p99), ' \
                     'and identify slowest or most-failing job classes.'
  spec.homepage = 'https://github.com/philiprehberger/rb-job-meter'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]

  spec.require_paths = ["lib"]
end

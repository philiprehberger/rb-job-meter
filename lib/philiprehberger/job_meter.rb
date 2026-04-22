# frozen_string_literal: true

require_relative 'job_meter/version'
require_relative 'job_meter/collector'
require_relative 'job_meter/stats'
require_relative 'job_meter/report'
require_relative 'job_meter/bucket'
require_relative 'job_meter/histogram'
require_relative 'job_meter/exporter'

module Philiprehberger
  module JobMeter
    @collector = Collector.new
    @buckets = {}

    module_function

    def record(job_class, duration:, success:, tags: {})
      @collector.record(job_class, duration: duration, success: success, tags: tags)
      (@buckets[job_class] ||= Bucket.new).record(duration: duration, success: success)
    end

    def measure(job_class, tags: {})
      raise ArgumentError, 'measure requires a block' unless block_given?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      success = true
      begin
        yield
      rescue StandardError
        success = false
        raise
      ensure
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        record(job_class, duration: duration, success: success, tags: tags)
      end
    end

    def tag_values(job_class, key)
      @collector.tag_values(job_class, key)
    end

    def clear!(job_class)
      cleared = @collector.clear!(job_class)
      bucket = @buckets.delete(job_class)
      bucket&.reset!
      cleared
    end

    def trending(job_class)
      bucket = @buckets[job_class]
      unless bucket
        return Bucket::WINDOWS.each_with_object({}) do |(label, _), h|
          h[label] = { avg_duration: 0.0, success_rate: 0.0, total: 0, failed: 0 }
        end
      end

      bucket.trending
    end

    def stats(job_class, tags: {})
      data = @collector.entries(job_class, tags: tags)
      return nil unless data

      Stats.compute(data[:durations], data[:successes])
    end

    def histogram(job_class, buckets:)
      data = @collector.entries(job_class)
      return nil unless data

      Histogram.compute(data[:durations], buckets)
    end

    def to_prometheus
      Exporter.to_prometheus(@collector)
    end

    def to_json_export
      Exporter.to_json_export(@collector)
    end

    def top_slowest(num = 5)
      Report.top_slowest(@collector, num)
    end

    def top_failing(num = 5)
      Report.top_failing(@collector, num)
    end

    def reset!
      @collector.reset!
      @buckets.each_value(&:reset!)
      @buckets.clear
    end
  end
end

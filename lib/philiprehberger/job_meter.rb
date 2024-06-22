# frozen_string_literal: true

require_relative 'job_meter/version'
require_relative 'job_meter/collector'
require_relative 'job_meter/stats'
require_relative 'job_meter/report'
require_relative 'job_meter/bucket'

module Philiprehberger
  module JobMeter
    @collector = Collector.new
    @buckets = {}

    module_function

    def record(job_class, duration:, success:)
      @collector.record(job_class, duration: duration, success: success)
      (@buckets[job_class] ||= Bucket.new).record(duration: duration, success: success)
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

    def stats(job_class)
      data = @collector.entries(job_class)
      return nil unless data

      Stats.compute(data[:durations], data[:successes])
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

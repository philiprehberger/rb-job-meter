# frozen_string_literal: true

require_relative 'job_meter/version'
require_relative 'job_meter/collector'
require_relative 'job_meter/stats'
require_relative 'job_meter/report'

module Philiprehberger
  module JobMeter
    @collector = Collector.new

    module_function

    def record(job_class, duration:, success:)
      @collector.record(job_class, duration: duration, success: success)
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
    end
  end
end

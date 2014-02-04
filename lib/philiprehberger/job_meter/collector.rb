# frozen_string_literal: true

module Philiprehberger
  module JobMeter
    class Collector
      def initialize
        @mutex = Mutex.new
        @data = {}
      end

      def record(job_class, duration:, success:)
        @mutex.synchronize do
          @data[job_class] ||= { durations: [], successes: [] }
          @data[job_class][:durations] << duration
          @data[job_class][:successes] << success
        end
      end

      def entries(job_class)
        @mutex.synchronize do
          entry = @data[job_class]
          return nil unless entry

          { durations: entry[:durations].dup, successes: entry[:successes].dup }
        end
      end

      def all_job_classes
        @mutex.synchronize { @data.keys.dup }
      end

      def reset!
        @mutex.synchronize { @data.clear }
      end
    end
  end
end

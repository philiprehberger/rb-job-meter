# frozen_string_literal: true

module Philiprehberger
  module JobMeter
    class Collector
      def initialize
        @mutex = Mutex.new
        @data = {}
      end

      def record(job_class, duration:, success:, tags: {})
        @mutex.synchronize do
          @data[job_class] ||= { durations: [], successes: [], tags: [] }
          @data[job_class][:durations] << duration
          @data[job_class][:successes] << success
          @data[job_class][:tags] << tags
        end
      end

      def entries(job_class, tags: {})
        @mutex.synchronize do
          entry = @data[job_class]
          return nil unless entry

          if tags.empty?
            { durations: entry[:durations].dup, successes: entry[:successes].dup }
          else
            indices = entry[:tags].each_index.select do |i|
              tags.all? { |k, v| entry[:tags][i][k] == v }
            end
            return nil if indices.empty?

            {
              durations: indices.map { |i| entry[:durations][i] },
              successes: indices.map { |i| entry[:successes][i] }
            }
          end
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

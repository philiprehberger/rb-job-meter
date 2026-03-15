# frozen_string_literal: true

module Philiprehberger
  module JobMeter
    module Report
      module_function

      def top_slowest(collector, num)
        ranked = build_stats(collector)
        ranked.sort_by { |entry| -entry[:avg_duration] }
              .first(num)
      end

      def top_failing(collector, num)
        ranked = build_stats(collector)
        ranked.sort_by { |entry| entry[:success_rate] }
              .first(num)
      end

      def build_stats(collector)
        collector.all_job_classes.map do |job_class|
          data = collector.entries(job_class)
          stats = Stats.compute(data[:durations], data[:successes])
          stats.merge(job_class: job_class)
        end
      end

      private_class_method :build_stats
    end
  end
end

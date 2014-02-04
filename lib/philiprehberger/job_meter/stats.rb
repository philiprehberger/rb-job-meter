# frozen_string_literal: true

module Philiprehberger
  module JobMeter
    module Stats
      module_function

      def percentile(sorted_values, pct)
        return 0.0 if sorted_values.empty?

        rank = (pct / 100.0 * (sorted_values.length - 1))
        lower = sorted_values[rank.floor]
        upper = sorted_values[rank.ceil]
        lower + ((upper - lower) * (rank - rank.floor))
      end

      def success_rate(successes)
        return 0.0 if successes.empty?

        successes.count(true).to_f / successes.length
      end

      def compute(durations, successes)
        sorted = durations.sort
        {
          avg_duration: sorted.sum.to_f / sorted.length,
          p50_duration: percentile(sorted, 50),
          p95_duration: percentile(sorted, 95),
          p99_duration: percentile(sorted, 99),
          success_rate: success_rate(successes),
          total: successes.length,
          failed: successes.count(false)
        }
      end
    end
  end
end

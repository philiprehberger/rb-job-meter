# frozen_string_literal: true

module Philiprehberger
  module JobMeter
    module Histogram
      module_function

      def compute(durations, buckets)
        sorted_buckets = buckets.sort
        result = {}

        sorted_buckets.each_with_index do |upper, index|
          lower = index.zero? ? 0 : sorted_buckets[index - 1]
          label = "#{lower}-#{upper}"
          result[label] = durations.count { |d| d >= lower && d < upper }
        end

        last = sorted_buckets.last
        result["#{last}+"] = durations.count { |d| d >= last }

        result
      end
    end
  end
end

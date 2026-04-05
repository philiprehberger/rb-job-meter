# frozen_string_literal: true

module Philiprehberger
  module JobMeter
    class Bucket
      WINDOWS = { last_1m: 60, last_5m: 300, last_15m: 900 }.freeze

      def initialize
        @mutex = Mutex.new
        @events = []
      end

      def record(duration:, success:)
        @mutex.synchronize do
          @events << { at: Process.clock_gettime(Process::CLOCK_MONOTONIC), duration: duration, success: success }
        end
      end

      def trending
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @mutex.synchronize do
          prune(now)
          WINDOWS.each_with_object({}) do |(label, window), result|
            subset = @events.select { |e| e[:at] >= now - window }
            result[label] = compute(subset)
          end
        end
      end

      def reset!
        @mutex.synchronize { @events.clear }
      end

      private

      def prune(now)
        cutoff = now - WINDOWS.values.max
        @events.reject! { |e| e[:at] < cutoff }
      end

      def compute(events)
        return { avg_duration: 0.0, success_rate: 0.0, total: 0, failed: 0 } if events.empty?

        durations = events.map { |e| e[:duration] }
        successes = events.map { |e| e[:success] }
        failed = successes.count(false)
        {
          avg_duration: durations.sum.to_f / durations.size,
          success_rate: successes.count(true).to_f / successes.size,
          total: events.size,
          failed: failed
        }
      end
    end
  end
end

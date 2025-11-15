# frozen_string_literal: true

require 'json'

module Philiprehberger
  module JobMeter
    module Exporter
      module_function

      def to_prometheus(collector)
        lines = []
        collector.all_job_classes.each do |job_class|
          data = collector.entries(job_class)
          next unless data

          stats = Stats.compute(data[:durations], data[:successes])
          sanitize_metric_name(job_class)

          lines << '# HELP job_duration_seconds Duration of job executions'
          lines << '# TYPE job_duration_seconds gauge'
          lines << "job_duration_seconds_avg{job_class=\"#{job_class}\"} #{format_value(stats[:avg_duration])}"
          lines << "job_duration_seconds_p50{job_class=\"#{job_class}\"} #{format_value(stats[:p50_duration])}"
          lines << "job_duration_seconds_p95{job_class=\"#{job_class}\"} #{format_value(stats[:p95_duration])}"
          lines << "job_duration_seconds_p99{job_class=\"#{job_class}\"} #{format_value(stats[:p99_duration])}"
          lines << '# HELP job_executions_total Total number of job executions'
          lines << '# TYPE job_executions_total counter'
          lines << "job_executions_total{job_class=\"#{job_class}\"} #{stats[:total]}"
          lines << '# HELP job_failures_total Total number of failed job executions'
          lines << '# TYPE job_failures_total counter'
          lines << "job_failures_total{job_class=\"#{job_class}\"} #{stats[:failed]}"
          lines << '# HELP job_success_rate Success rate of job executions'
          lines << '# TYPE job_success_rate gauge'
          lines << "job_success_rate{job_class=\"#{job_class}\"} #{format_value(stats[:success_rate])}"
        end

        "#{lines.join("\n")}\n"
      end

      def to_json_export(collector)
        jobs = collector.all_job_classes.map do |job_class|
          data = collector.entries(job_class)
          next unless data

          stats = Stats.compute(data[:durations], data[:successes])
          {
            job_class: job_class,
            stats: stats
          }
        end.compact

        JSON.generate({ jobs: jobs })
      end

      def sanitize_metric_name(name)
        name.gsub(/[^a-zA-Z0-9_]/, '_').downcase
      end

      def format_value(value)
        value == value.to_i ? value.to_i.to_s : value.to_s
      end

      private_class_method :sanitize_metric_name, :format_value
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::JobMeter do
  before { described_class.reset! }

  describe 'VERSION' do
    it 'returns the current version' do
      expect(Philiprehberger::JobMeter::VERSION).not_to be_nil
    end

    it 'is a valid semver string' do
      expect(Philiprehberger::JobMeter::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe '.record and .stats' do
    it 'records a job execution and returns stats' do
      described_class.record('SendEmail', duration: 1.5, success: true)
      described_class.record('SendEmail', duration: 2.5, success: true)

      result = described_class.stats('SendEmail')

      expect(result[:avg_duration]).to eq(2.0)
      expect(result[:total]).to eq(2)
      expect(result[:failed]).to eq(0)
    end

    it 'returns nil for unknown job class' do
      expect(described_class.stats('Unknown')).to be_nil
    end

    it 'records a job with zero duration' do
      described_class.record('ZeroJob', duration: 0.0, success: true)

      result = described_class.stats('ZeroJob')

      expect(result[:avg_duration]).to eq(0.0)
      expect(result[:p50_duration]).to eq(0.0)
      expect(result[:total]).to eq(1)
    end

    it 'records only failures' do
      3.times { described_class.record('FailJob', duration: 1.0, success: false) }

      result = described_class.stats('FailJob')

      expect(result[:success_rate]).to eq(0.0)
      expect(result[:failed]).to eq(3)
      expect(result[:total]).to eq(3)
    end

    it 'records only successes' do
      3.times { described_class.record('GoodJob', duration: 1.0, success: true) }

      result = described_class.stats('GoodJob')

      expect(result[:success_rate]).to eq(1.0)
      expect(result[:failed]).to eq(0)
    end

    it 'tracks multiple job classes independently' do
      described_class.record('JobA', duration: 1.0, success: true)
      described_class.record('JobB', duration: 5.0, success: false)

      stats_a = described_class.stats('JobA')
      stats_b = described_class.stats('JobB')

      expect(stats_a[:avg_duration]).to eq(1.0)
      expect(stats_a[:success_rate]).to eq(1.0)
      expect(stats_b[:avg_duration]).to eq(5.0)
      expect(stats_b[:success_rate]).to eq(0.0)
    end

    it 'handles a single job recording' do
      described_class.record('SingleJob', duration: 3.14, success: true)

      result = described_class.stats('SingleJob')

      expect(result[:avg_duration]).to eq(3.14)
      expect(result[:total]).to eq(1)
    end
  end

  describe 'percentile calculations' do
    it 'computes the 95th percentile duration' do
      values = (1..100).to_a
      values.each do |v|
        described_class.record('BatchJob', duration: v.to_f, success: true)
      end

      result = described_class.stats('BatchJob')

      expect(result[:p95_duration]).to be_within(1.0).of(95.0)
    end

    it 'computes percentiles for a single job' do
      described_class.record('OneJob', duration: 42.0, success: true)

      result = described_class.stats('OneJob')

      expect(result[:p50_duration]).to eq(42.0)
      expect(result[:p95_duration]).to eq(42.0)
      expect(result[:p99_duration]).to eq(42.0)
    end

    it 'computes percentiles for two jobs' do
      described_class.record('TwoJob', duration: 10.0, success: true)
      described_class.record('TwoJob', duration: 20.0, success: true)

      result = described_class.stats('TwoJob')

      expect(result[:p50_duration]).to eq(15.0)
      expect(result[:p95_duration]).to be_within(0.5).of(19.5)
      expect(result[:p99_duration]).to be_within(0.1).of(19.9)
    end

    it 'returns 0.0 for percentile of empty values' do
      result = Philiprehberger::JobMeter::Stats.percentile([], 95)
      expect(result).to eq(0.0)
    end

    it 'computes p50 as the median for odd count' do
      [1.0, 2.0, 3.0, 4.0, 5.0].each do |d|
        described_class.record('OddJob', duration: d, success: true)
      end

      result = described_class.stats('OddJob')

      expect(result[:p50_duration]).to eq(3.0)
    end
  end

  describe 'success_rate' do
    it 'computes success rate correctly' do
      8.times { described_class.record('ImportJob', duration: 1.0, success: true) }
      2.times { described_class.record('ImportJob', duration: 1.0, success: false) }

      result = described_class.stats('ImportJob')

      expect(result[:success_rate]).to eq(0.8)
      expect(result[:failed]).to eq(2)
    end

    it 'returns 0.0 for empty successes array' do
      result = Philiprehberger::JobMeter::Stats.success_rate([])
      expect(result).to eq(0.0)
    end

    it 'handles 50/50 success/failure ratio' do
      5.times { described_class.record('HalfJob', duration: 1.0, success: true) }
      5.times { described_class.record('HalfJob', duration: 1.0, success: false) }

      result = described_class.stats('HalfJob')

      expect(result[:success_rate]).to eq(0.5)
      expect(result[:failed]).to eq(5)
    end
  end

  describe '.top_slowest' do
    it 'returns jobs sorted by avg duration descending' do
      described_class.record('Fast', duration: 0.1, success: true)
      described_class.record('Slow', duration: 5.0, success: true)
      described_class.record('Medium', duration: 2.0, success: true)

      result = described_class.top_slowest(2)

      expect(result.length).to eq(2)
      expect(result.first[:job_class]).to eq('Slow')
      expect(result.last[:job_class]).to eq('Medium')
    end

    it 'returns all jobs when num exceeds total job classes' do
      described_class.record('OnlyJob', duration: 1.0, success: true)

      result = described_class.top_slowest(10)

      expect(result.length).to eq(1)
      expect(result.first[:job_class]).to eq('OnlyJob')
    end

    it 'returns empty array when no jobs recorded' do
      result = described_class.top_slowest(5)
      expect(result).to eq([])
    end

    it 'uses average duration for ranking' do
      described_class.record('Varies', duration: 1.0, success: true)
      described_class.record('Varies', duration: 9.0, success: true)
      described_class.record('Steady', duration: 4.0, success: true)
      described_class.record('Steady', duration: 4.0, success: true)

      result = described_class.top_slowest(2)

      expect(result.first[:job_class]).to eq('Varies')
      expect(result.first[:avg_duration]).to eq(5.0)
    end
  end

  describe '.top_failing' do
    it 'returns jobs sorted by success rate ascending' do
      3.times { described_class.record('Reliable', duration: 1.0, success: true) }
      described_class.record('Flaky', duration: 1.0, success: true)
      described_class.record('Flaky', duration: 1.0, success: false)
      2.times { described_class.record('Broken', duration: 1.0, success: false) }

      result = described_class.top_failing(2)

      expect(result.length).to eq(2)
      expect(result.first[:job_class]).to eq('Broken')
      expect(result.last[:job_class]).to eq('Flaky')
    end

    it 'returns all jobs when num exceeds total job classes' do
      described_class.record('SingleJob', duration: 1.0, success: false)

      result = described_class.top_failing(10)

      expect(result.length).to eq(1)
    end

    it 'returns empty array when no jobs recorded' do
      result = described_class.top_failing(5)
      expect(result).to eq([])
    end
  end

  describe '.reset!' do
    it 'clears all recorded metrics' do
      described_class.record('SendEmail', duration: 1.0, success: true)
      described_class.reset!

      expect(described_class.stats('SendEmail')).to be_nil
    end

    it 'allows new recordings after reset' do
      described_class.record('Job', duration: 1.0, success: true)
      described_class.reset!
      described_class.record('Job', duration: 2.0, success: false)

      result = described_class.stats('Job')

      expect(result[:total]).to eq(1)
      expect(result[:avg_duration]).to eq(2.0)
      expect(result[:success_rate]).to eq(0.0)
    end

    it 'clears multiple job classes' do
      described_class.record('JobA', duration: 1.0, success: true)
      described_class.record('JobB', duration: 2.0, success: false)
      described_class.reset!

      expect(described_class.stats('JobA')).to be_nil
      expect(described_class.stats('JobB')).to be_nil
    end
  end

  describe 'thread safety' do
    it 'handles concurrent records without errors' do
      threads = 10.times.map do |_i|
        Thread.new do
          50.times do
            described_class.record('ConcurrentJob', duration: rand(0.1..5.0), success: [true, false].sample)
          end
        end
      end

      threads.each(&:join)

      result = described_class.stats('ConcurrentJob')

      expect(result[:total]).to eq(500)
    end

    it 'handles concurrent records to different job classes' do
      threads = 5.times.map do |i|
        Thread.new do
          20.times do
            described_class.record("ThreadJob#{i}", duration: 1.0, success: true)
          end
        end
      end

      threads.each(&:join)

      5.times do |i|
        result = described_class.stats("ThreadJob#{i}")
        expect(result[:total]).to eq(20)
      end
    end
  end

  describe '.trending' do
    it 'returns stats for all three time windows' do
      described_class.record('TrendJob', duration: 1.0, success: true)
      result = described_class.trending('TrendJob')
      expect(result.keys).to contain_exactly(:last_1m, :last_5m, :last_15m)
    end

    it 'returns zero stats for unknown job class' do
      result = described_class.trending('UnknownJob')
      %i[last_1m last_5m last_15m].each do |window|
        expect(result[window][:total]).to eq(0)
        expect(result[window][:avg_duration]).to eq(0.0)
      end
    end

    it 'includes correct totals within window' do
      3.times { described_class.record('CountJob', duration: 2.0, success: true) }
      2.times { described_class.record('CountJob', duration: 1.0, success: false) }
      result = described_class.trending('CountJob')
      expect(result[:last_1m][:total]).to eq(5)
      expect(result[:last_1m][:failed]).to eq(2)
    end

    it 'calculates average duration within window' do
      described_class.record('AvgJob', duration: 2.0, success: true)
      described_class.record('AvgJob', duration: 4.0, success: true)
      result = described_class.trending('AvgJob')
      expect(result[:last_1m][:avg_duration]).to eq(3.0)
    end

    it 'calculates success rate within window' do
      3.times { described_class.record('RateJob', duration: 1.0, success: true) }
      described_class.record('RateJob', duration: 1.0, success: false)
      result = described_class.trending('RateJob')
      expect(result[:last_1m][:success_rate]).to eq(0.75)
    end

    it 'is cleared by reset!' do
      described_class.record('ResetTrendJob', duration: 1.0, success: true)
      described_class.reset!
      result = described_class.trending('ResetTrendJob')
      expect(result[:last_1m][:total]).to eq(0)
    end
  end

  describe '.record with tags' do
    it 'records a job with tags' do
      described_class.record('SendEmail', duration: 1.0, success: true, tags: { queue: 'default' })
      result = described_class.stats('SendEmail')
      expect(result[:total]).to eq(1)
    end

    it 'records multiple jobs with different tags' do
      described_class.record('SendEmail', duration: 1.0, success: true, tags: { queue: 'high' })
      described_class.record('SendEmail', duration: 2.0, success: false, tags: { queue: 'low' })
      described_class.record('SendEmail', duration: 3.0, success: true, tags: { queue: 'high' })

      result = described_class.stats('SendEmail')
      expect(result[:total]).to eq(3)
    end

    it 'defaults to empty tags when none provided' do
      described_class.record('SendEmail', duration: 1.0, success: true)
      result = described_class.stats('SendEmail')
      expect(result[:total]).to eq(1)
    end

    it 'supports multiple tag keys' do
      described_class.record('SendEmail', duration: 1.0, success: true, tags: { queue: 'high', env: 'production' })
      result = described_class.stats('SendEmail', tags: { queue: 'high', env: 'production' })
      expect(result[:total]).to eq(1)
    end
  end

  describe '.stats with tags filtering' do
    it 'filters by a single tag' do
      described_class.record('Job', duration: 1.0, success: true, tags: { queue: 'high' })
      described_class.record('Job', duration: 2.0, success: false, tags: { queue: 'low' })
      described_class.record('Job', duration: 3.0, success: true, tags: { queue: 'high' })

      result = described_class.stats('Job', tags: { queue: 'high' })
      expect(result[:total]).to eq(2)
      expect(result[:avg_duration]).to eq(2.0)
      expect(result[:success_rate]).to eq(1.0)
    end

    it 'filters by multiple tags' do
      described_class.record('Job', duration: 1.0, success: true, tags: { queue: 'high', env: 'prod' })
      described_class.record('Job', duration: 2.0, success: true, tags: { queue: 'high', env: 'staging' })
      described_class.record('Job', duration: 3.0, success: false, tags: { queue: 'low', env: 'prod' })

      result = described_class.stats('Job', tags: { queue: 'high', env: 'prod' })
      expect(result[:total]).to eq(1)
      expect(result[:avg_duration]).to eq(1.0)
    end

    it 'returns nil when no records match tags' do
      described_class.record('Job', duration: 1.0, success: true, tags: { queue: 'high' })
      result = described_class.stats('Job', tags: { queue: 'nonexistent' })
      expect(result).to be_nil
    end

    it 'returns all records when tags filter is empty' do
      described_class.record('Job', duration: 1.0, success: true, tags: { queue: 'high' })
      described_class.record('Job', duration: 2.0, success: true, tags: { queue: 'low' })

      result = described_class.stats('Job', tags: {})
      expect(result[:total]).to eq(2)
    end

    it 'matches partial tags correctly' do
      described_class.record('Job', duration: 1.0, success: true, tags: { queue: 'high', env: 'prod', region: 'us' })
      described_class.record('Job', duration: 2.0, success: true, tags: { queue: 'high', env: 'staging' })

      result = described_class.stats('Job', tags: { queue: 'high' })
      expect(result[:total]).to eq(2)
    end
  end

  describe '.histogram' do
    it 'distributes durations into buckets' do
      [0.05, 0.2, 0.3, 0.7, 1.5, 3.0, 6.0].each do |d|
        described_class.record('HistJob', duration: d, success: true)
      end

      result = described_class.histogram('HistJob', buckets: [0.1, 0.5, 1.0, 5.0])
      expect(result['0-0.1']).to eq(1)
      expect(result['0.1-0.5']).to eq(2)
      expect(result['0.5-1.0']).to eq(1)
      expect(result['1.0-5.0']).to eq(2)
      expect(result['5.0+']).to eq(1)
    end

    it 'returns nil for unknown job class' do
      result = described_class.histogram('Unknown', buckets: [1.0, 5.0])
      expect(result).to be_nil
    end

    it 'handles all durations in a single bucket' do
      3.times { described_class.record('SmallJob', duration: 0.01, success: true) }

      result = described_class.histogram('SmallJob', buckets: [0.1, 1.0])
      expect(result['0-0.1']).to eq(3)
      expect(result['0.1-1.0']).to eq(0)
      expect(result['1.0+']).to eq(0)
    end

    it 'handles all durations above last bucket' do
      3.times { described_class.record('BigJob', duration: 100.0, success: true) }

      result = described_class.histogram('BigJob', buckets: [1.0, 5.0])
      expect(result['0-1.0']).to eq(0)
      expect(result['1.0-5.0']).to eq(0)
      expect(result['5.0+']).to eq(3)
    end

    it 'handles a single bucket boundary' do
      described_class.record('SplitJob', duration: 0.5, success: true)
      described_class.record('SplitJob', duration: 1.5, success: true)

      result = described_class.histogram('SplitJob', buckets: [1.0])
      expect(result['0-1.0']).to eq(1)
      expect(result['1.0+']).to eq(1)
    end

    it 'sorts unsorted bucket boundaries' do
      [0.2, 0.8, 3.0].each do |d|
        described_class.record('SortJob', duration: d, success: true)
      end

      result = described_class.histogram('SortJob', buckets: [5.0, 0.5, 1.0])
      expect(result.keys).to eq(['0-0.5', '0.5-1.0', '1.0-5.0', '5.0+'])
    end
  end

  describe '.to_prometheus' do
    it 'returns prometheus formatted output' do
      described_class.record('ExportJob', duration: 1.0, success: true)
      described_class.record('ExportJob', duration: 2.0, success: false)

      output = described_class.to_prometheus

      expect(output).to include('# HELP job_duration_seconds')
      expect(output).to include('# TYPE job_duration_seconds gauge')
      expect(output).to include('job_duration_seconds_avg{job_class="ExportJob"}')
      expect(output).to include('job_executions_total{job_class="ExportJob"} 2')
      expect(output).to include('job_failures_total{job_class="ExportJob"} 1')
      expect(output).to include('job_success_rate{job_class="ExportJob"}')
    end

    it 'includes multiple job classes' do
      described_class.record('JobA', duration: 1.0, success: true)
      described_class.record('JobB', duration: 2.0, success: true)

      output = described_class.to_prometheus

      expect(output).to include('job_class="JobA"')
      expect(output).to include('job_class="JobB"')
    end

    it 'returns only a newline when no jobs recorded' do
      output = described_class.to_prometheus
      expect(output).to eq("\n")
    end

    it 'includes percentile metrics' do
      described_class.record('PctJob', duration: 1.0, success: true)

      output = described_class.to_prometheus

      expect(output).to include('job_duration_seconds_p50{job_class="PctJob"}')
      expect(output).to include('job_duration_seconds_p95{job_class="PctJob"}')
      expect(output).to include('job_duration_seconds_p99{job_class="PctJob"}')
    end
  end

  describe '.to_json_export' do
    it 'returns valid JSON' do
      described_class.record('JsonJob', duration: 1.5, success: true)

      output = described_class.to_json_export
      parsed = JSON.parse(output)

      expect(parsed).to have_key('jobs')
      expect(parsed['jobs'].length).to eq(1)
      expect(parsed['jobs'].first['job_class']).to eq('JsonJob')
    end

    it 'includes stats in export' do
      described_class.record('StatsExport', duration: 2.0, success: true)
      described_class.record('StatsExport', duration: 4.0, success: false)

      output = described_class.to_json_export
      parsed = JSON.parse(output)
      job = parsed['jobs'].first

      expect(job['stats']['avg_duration']).to eq(3.0)
      expect(job['stats']['total']).to eq(2)
      expect(job['stats']['failed']).to eq(1)
      expect(job['stats']['success_rate']).to eq(0.5)
    end

    it 'includes multiple job classes' do
      described_class.record('JsonA', duration: 1.0, success: true)
      described_class.record('JsonB', duration: 2.0, success: false)

      output = described_class.to_json_export
      parsed = JSON.parse(output)

      job_names = parsed['jobs'].map { |j| j['job_class'] }
      expect(job_names).to include('JsonA', 'JsonB')
    end

    it 'returns empty jobs array when no jobs recorded' do
      output = described_class.to_json_export
      parsed = JSON.parse(output)

      expect(parsed['jobs']).to eq([])
    end
  end

  describe 'many jobs statistics' do
    it 'computes correct stats for a large number of recordings' do
      1000.times do |i|
        described_class.record('BulkJob', duration: (i + 1).to_f, success: i.even?)
      end

      result = described_class.stats('BulkJob')

      expect(result[:total]).to eq(1000)
      expect(result[:avg_duration]).to eq(500.5)
      expect(result[:failed]).to eq(500)
      expect(result[:success_rate]).to eq(0.5)
    end
  end
end

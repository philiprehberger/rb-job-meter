# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::JobMeter do
  before { described_class.reset! }

  describe 'VERSION' do
    it 'returns the current version' do
      expect(Philiprehberger::JobMeter::VERSION).not_to be_nil
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
  end

  describe 'p95 calculation' do
    it 'computes the 95th percentile duration' do
      values = (1..100).to_a
      values.each do |v|
        described_class.record('BatchJob', duration: v.to_f, success: true)
      end

      result = described_class.stats('BatchJob')

      expect(result[:p95_duration]).to be_within(1.0).of(95.0)
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
  end

  describe '.reset!' do
    it 'clears all recorded metrics' do
      described_class.record('SendEmail', duration: 1.0, success: true)
      described_class.reset!

      expect(described_class.stats('SendEmail')).to be_nil
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
  end
end

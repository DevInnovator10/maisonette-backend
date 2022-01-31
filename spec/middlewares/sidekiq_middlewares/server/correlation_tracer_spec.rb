# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SidekiqMiddlewares::Server::CorrelationTracer do
  subject(:middleware) do
    described_class.new.call(worker, job) { job['args'] }
  end

  let(:worker) {}
  let(:job) { { 'args' => [arg1, correlation] } }
  let(:arg1) { 1 }

  context 'when the correlation args exists' do
    let(:correlation) do
      { 'trace_id' => 1337,
        'span_id' => 9001 }
    end

    it 'removes correlation from args' do
      expect(middleware).to match_array([arg1])
    end

    it 'uses the passed in correlation ids for the active correlation' do
      middleware
      expect(Datadog.tracer.active_correlation.trace_id).to eq 1337
      expect(Datadog.tracer.active_correlation.span_id).to eq 9001
    end
  end
end

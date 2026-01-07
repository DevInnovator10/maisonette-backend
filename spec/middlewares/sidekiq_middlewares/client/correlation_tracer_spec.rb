# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SidekiqMiddlewares::Client::CorrelationTracer do
  subject(:middleware) do
    described_class.new.call(worker, job) { job['args'] }
  end

  let(:worker) {}
  let(:job) { { 'args' => [arg1] } }
  let(:arg1) { 1 }
  let(:correlation) do
    { 'trace_id' => Datadog.tracer.active_correlation.trace_id,
      'span_id' => Datadog.tracer.active_correlation.span_id }
  end

  context 'when sidekiq testing is enabled', sidekiq_inline: true do
    it 'does not add the correlation args' do
      expect(middleware).to match_array([arg1])
    end
  end

  context 'when sidekiq testing is disabled' do
    it 'does add the correlation args' do
      expect(middleware).to match_array([arg1, correlation])
    end

    context 'when there is already correlation attributes from a retry' do
      let(:job) { { 'args' => [arg1, old_correlation] } }
      let(:old_correlation) do
        { 'trace_id' => 'old_trace_id',
          'span_id' => 'old_span_id' }
      end

      it 'does not add the correlation args' do
        expect(middleware).to match_array([arg1, old_correlation])
      end
    end
  end
end

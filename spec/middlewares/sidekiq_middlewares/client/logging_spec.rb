# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SidekiqMiddlewares::Client::Logging, sidekiq_inline: true do
  subject(:middleware) { described_class.new.call(worker, job, queue, redis_pool) { true } }

  let(:queue) { 'default' }
  let(:worker) { FakeWorker }
  let(:job) do
    { 'queue' => queue,
      'class' => worker.name,
      'args' => [arg1] }
  end
  let(:logged_job) do
    { 'queue' => queue,
      'class' => worker.name,
      'args' => [arg1.to_s] }
  end
  let(:arg1) { 1 }
  let(:redis_pool) { 'redis pool' }

  before do
    allow(Rails.logger).to receive(:info)

    middleware
  end

  it 'logs the jobs' do
    expect(Rails.logger).to have_received(:info).with(sidekiq: logged_job, message: "sidekiq queueing: #{worker}")
  end
end

class FakeWorker
end

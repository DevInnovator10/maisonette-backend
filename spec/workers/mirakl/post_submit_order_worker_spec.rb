# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::PostSubmitOrderWorker do
  subject(:post_order_submit_worker) { described_class.new.perform(mirakl_order.id) }

  let(:mirakl_order) { instance_double Mirakl::Order, id: 51 }
  let(:context) do
    double Interactor::Context, exception: exception # rubocop:disable RSpec/VerifiedDoubles
  end

  before do
    allow(Mirakl::Order).to receive_messages(find: mirakl_order)
    allow(Mirakl::PostSubmitOrderOrganizer).to receive_messages(call: context)
  end

  context 'when it is successful' do
    let(:exception) {}

    before { post_order_submit_worker }

    it 'calls PostSubmitOrderOrganizer' do
      expect(Mirakl::PostSubmitOrderOrganizer).to have_received(:call)

    end
  end

  context 'when it fails with Errno::EADDRINUSE' do
    let(:exception) { Errno::EADDRINUSE.new }

    it 'raises an exception' do
      expect { post_order_submit_worker }.to raise_exception(exception)
    end
  end
end

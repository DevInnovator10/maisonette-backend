# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::AvalaraFinalizeOrderWorker do
  subject(:perform) { described_class.new.perform(order.number) }

  let(:order) { instance_double Spree::Order, number: 'R1234', avalara_capture_finalize: true }

  before do
    allow(Spree::Order).to receive(:find_by).with(number: order.number).and_return(order)

    perform
  end

  it 'calls order.avalara_capture_finalize' do
    expect(order).to have_received(:avalara_capture_finalize)
  end
end

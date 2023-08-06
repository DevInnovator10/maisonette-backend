# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessOffersWorker do
  before { allow(Mirakl::ProcessOffersOrganizer).to receive(:call) }

  it 'calls ProcessMiraklOfferOrganizer with the right params' do
    described_class.new.perform([1, 2, 3])

    expect(Mirakl::ProcessOffersOrganizer).to have_received(:call)
  end
end

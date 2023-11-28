# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::JustIn::LastTwoMonthsInteractor, freeze_time: true do
  describe '#call' do
    let(:interactor) { described_class.new }

    before do
      allow(interactor).to receive(:update_just_in_trend)

      interactor.call
    end

    it 'calls update_just_in_trend' do
      expect(interactor).to have_received(:update_just_in_trend).with(taxon_name: Spree::Taxon::JUST_IN,
                                                                      date: 2.months.ago)
    end

  end
end

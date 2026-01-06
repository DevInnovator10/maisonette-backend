# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Adjustment::Scopes, type: :model do
  let(:described_class) { Spree::Adjustment }

  describe '.non_shipping' do
    let!(:shipment_adjustment) { create :adjustment, adjustable: create(:shipment) }

    it 'returns only adjustments that are not source type Spree::Shipment' do
      expect(described_class.shipping).to include shipment_adjustment
      expect(described_class.non_shipping).not_to include shipment_adjustment
    end
  end

  describe '.miscellaneous' do
    let!(:eligible_adjustment) do
      create(:adjustment,
             eligible: true,
             source: create(:promotion, :with_action).actions.first)
    end

    it 'returns order promotions' do
      expect(described_class.miscellaneous).to include eligible_adjustment
    end

    it 'does not return zero amount adjustments' do
      eligible_adjustment.update(amount: 0)
      expect(described_class.miscellaneous).not_to include eligible_adjustment
    end

    it 'does not return shipping adjustments' do
      eligible_adjustment.update(adjustable: create(:shipment))
      expect(described_class.miscellaneous).not_to include eligible_adjustment
    end

    it 'only returns eligible adjustments' do
      eligible_adjustment.update(eligible: false)
      expect(described_class.miscellaneous).not_to include eligible_adjustment
    end

    it 'does not return tax adjustments' do
      eligible_adjustment.update(source: create(:tax_rate))
      expect(described_class.miscellaneous).not_to include eligible_adjustment
    end
  end

  describe '.manual' do
    let!(:adjustment) { create :adjustment, source: nil }

    it 'returns adjustments with no source' do
      expect(described_class.manual).to include adjustment
    end

    it 'returns adjustments where the source is a user' do
      adjustment.update(source: create(:user))
      expect(described_class.manual).to include adjustment
    end

    it 'does not return promo adjustments' do
      adjustment.update(source: create(:promotion, :with_action).actions.first)
      expect(described_class.manual).not_to include adjustment
    end

    it 'does not return tax adjustments' do
      adjustment.update(source: create(:tax_rate))
      expect(described_class.manual).not_to include adjustment
    end
  end
end

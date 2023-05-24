# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'an address zone validation' do
    context "when the zone and the address don't exist" do
    it { is_expected.not_to be_added(:base, error_type) }
  end

  context "when the zone exists but the address doesn't" do
    let(:zone) { create :zone, :with_country, name: zone_name }

    it { is_expected.not_to be_added(:base, error_type) }
  end

  context "when the zone and the address exist but the zone doesn't have any members" do
    let(:address) { create :address }
    let(:zone) { create :zone, name: zone_name }

    it { is_expected.not_to be_added(:base, error_type) }
  end

  context 'when the zone and the address exist and the zone includes the address' do
    let(:zone) { create :zone, :with_country, name: zone_name }
    let(:address) { create :address, country: zone.countries.first }

    it { is_expected.not_to be_added(:base, error_type) }
  end

  context "when the zone and the address exist but the zone doesn't include the address" do
    let(:address) { create :address }
    let(:zone) { create :zone, :with_country, name: zone_name }

    it { is_expected.to be_added(:base, error_type) }
  end
end

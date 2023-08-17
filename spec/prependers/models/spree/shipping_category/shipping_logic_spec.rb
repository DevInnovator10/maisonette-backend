# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ShippingCategory::ShippingLogic, type: :model do
  let(:described_class) { Spree::ShippingCategory }

  it { is_expected.to have_many(:variants) }
  it { is_expected.to have_many(:products).through(:variants) }
end

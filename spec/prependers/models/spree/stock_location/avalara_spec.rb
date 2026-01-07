# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::StockLocation::Avalara, type: :model do
  let(:described_class) { Spree::StockLocation }

  it { is_expected.to delegate_method(:avalara_code).to(:vendor) }
end

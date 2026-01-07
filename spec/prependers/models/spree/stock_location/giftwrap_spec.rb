# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::StockLocation::Giftwrap, type: :model do
  let(:described_class) { Spree::StockLocation }

  it { is_expected.to delegate_method(:giftwrap_service?).to(:vendor) }
end

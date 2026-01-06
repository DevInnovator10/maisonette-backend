# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::MarkDownSalePrice, type: :model do
  it { is_expected.to belong_to(:sale_price).dependent(:destroy) }
end

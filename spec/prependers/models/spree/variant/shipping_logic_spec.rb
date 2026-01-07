# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Variant::ShippingLogic, type: :model do
  subject { create(:variant) }

  it { is_expected.to belong_to(:shipping_category).required }
end

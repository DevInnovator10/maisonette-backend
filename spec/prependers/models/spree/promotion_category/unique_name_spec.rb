# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionCategory::UniqueName, type: :model do
  let(:described_class) { Spree::PromotionCategory }

  it { is_expected.to validate_uniqueness_of(:name) }
end

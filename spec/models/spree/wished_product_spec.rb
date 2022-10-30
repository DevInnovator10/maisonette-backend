# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::WishedProduct, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:wishlist).required }
    it { is_expected.to belong_to(:variant).required }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:variant_id).scoped_to(:wishlist_id) }
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Warehouse, mirakl: true do
  describe 'relations' do
    it { is_expected.to belong_to(:mirakl_shop).class_name('Mirakl::Shop') }
    it { is_expected.to belong_to(:address).class_name('Spree::Address') }

    it { is_expected.to validate_presence_of(:name) }
  end
end

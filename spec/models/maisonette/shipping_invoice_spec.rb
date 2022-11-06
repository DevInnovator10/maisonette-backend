# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::ShippingInvoice, type: :model do
  describe 'relations' do
    it { is_expected.to belong_to(:easypost_order).class_name('Easypost::Order').optional }
  end

  describe 'validation tests' do
    it { is_expected.to validate_uniqueness_of(:tracking_code) }
  end
end

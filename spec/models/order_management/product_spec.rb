# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::Product, type: :model do
  describe '.order_management_object_name' do
    subject(:order_management_object_name) do
      described_class.order_management_object_name
    end

    it { is_expected.to eq 'Product2' }
  end

  describe '.payload_presenter_class' do
    subject(:payload_presenter_class) do
      described_class.payload_presenter_class
    end

    it { is_expected.to eq OrderManagement::ProductPresenter }
  end
end

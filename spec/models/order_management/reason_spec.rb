# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::Reason, type: :model do
  describe '.payload_presenter_class' do
    subject(:payload_presenter_class) { described_class.payload_presenter_class }

    it 'return OrderManagement::ReasonPresenter' do
      is_expected.to eq OrderManagement::ReasonPresenter
    end
  end

  describe '.order_management_object_name' do
    subject(:order_management_object_name) { described_class.order_management_object_name }

    it 'return Reason' do
      is_expected.to eq 'Reason_Code__c'
    end
  end
end

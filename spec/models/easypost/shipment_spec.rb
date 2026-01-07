# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::Shipment, mirakl: true do
  it_behaves_like 'an Easypost active record model'

  describe 'relations' do
    it { is_expected.to belong_to(:easypost_order).class_name('Easypost::Order') }
    it { is_expected.to belong_to(:easypost_parcel).class_name('Easypost::Parcel') }
  end
end

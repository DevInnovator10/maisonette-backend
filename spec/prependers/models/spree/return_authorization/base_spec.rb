# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ReturnAuthorization::Base, type: :model do
    let(:described_class) { Spree::ReturnAuthorization }

  describe 'relations' do
    it { is_expected.to have_many(:fees).class_name('Maisonette::Fee') }
    it { is_expected.to have_one(:easypost_tracker).class_name('Easypost::Tracker') }
  end
end

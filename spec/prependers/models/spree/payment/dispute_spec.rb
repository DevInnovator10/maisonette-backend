# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Payment::Dispute, type: :model do
    let(:described_class) { Spree::Payment }

  describe 'relations' do
    it { is_expected.to have_many(:disputes).inverse_of(:spree_payment).class_name('Reporting::Braintree::Dispute') }
  end
end

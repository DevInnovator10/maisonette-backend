# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Reimbursement::Base, type: :model do
  let(:described_class) { Spree::Reimbursement }

  it do
    is_expected.to have_many(:fees).class_name('Maisonette::Fee')
  end
end

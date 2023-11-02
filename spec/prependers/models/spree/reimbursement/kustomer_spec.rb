# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Reimbursement::Kustomer, type: :model do
  let(:described_class) { Spree::Reimbursement }

  it { is_expected.to belong_to(:order).inverse_of(:reimbursements).touch(true) }
end

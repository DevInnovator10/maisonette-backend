# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Refund::Kustomer, type: :model do
  let(:described_class) { Spree::Refund }

  it { is_expected.to belong_to(:reimbursement).inverse_of(:refunds).optional(true).touch(true) }
end

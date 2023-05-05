# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Reimbursement::Mirakl, type: :model do
  let(:described_class) { Spree::Reimbursement }

  let(:reimbursement_class) { 'Mirakl::OrderLineReimbursement' }

  it do
    expect(described_class.new).to(
      have_many(:mirakl_order_line_reimbursements)
        .inverse_of(:reimbursement)
        .class_name(reimbursement_class)
    )
  end

  describe '#mirakl_order_line_reimbursement' do
    subject { reimbursement.mirakl_order_line_reimbursement }

    let(:mirakl_order_line_reimbursement) { build(:mirakl_order_line_reimbursement) }
    let(:reimbursement) { build(:reimbursement, mirakl_order_line_reimbursements: [mirakl_order_line_reimbursement]) }

    it { is_expected.to eq(mirakl_order_line_reimbursement) }
  end
end

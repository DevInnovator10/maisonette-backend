# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Fee, type: :model do
  it { is_expected.to define_enum_for(:fee_type).with_values(return: 1, restock: 2) }
  it { is_expected.to belong_to(:spree_reimbursement).class_name('Spree::Reimbursement').optional }
  it { is_expected.to belong_to(:spree_return_authorization).class_name('Spree::ReturnAuthorization').optional }
end

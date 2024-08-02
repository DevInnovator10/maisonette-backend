# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Spree::PermissionSets::MiraklDisplay do
  subject { ability }

  let(:ability) { Spree::Ability.new(user) }
  let(:user) { nil }
  let(:mirakl_order) { Mirakl::Order.new }
  let(:mirakl_order_line) { Mirakl::OrderLine.new }
  let(:mirakl_order_line_reimbursement) { Mirakl::OrderLineReimbursement.new }
  let(:mirakl_offer) { Mirakl::Offer.new }
  let(:mirakl_shop) { Mirakl::Shop.new }

  before do
    described_class.new(ability).activate!
  end

  it { is_expected.to be_able_to(:read, :mirakl_menu) }
  it { is_expected.to be_able_to(:read, mirakl_order) }
  it { is_expected.to be_able_to(:edit, mirakl_order) }
  it { is_expected.to be_able_to(:admin, mirakl_order) }
  it { is_expected.to be_able_to(:recreate_easypost_label, mirakl_order) }
  it { is_expected.to be_able_to(:fetch_easypost_errors, mirakl_order) }
  it { is_expected.to be_able_to(:send_packing_slip, mirakl_order) }

  it { is_expected.to be_able_to(:read, mirakl_order_line) }
  it { is_expected.to be_able_to(:admin, mirakl_order_line) }

  it { is_expected.to be_able_to(:read, mirakl_order_line_reimbursement) }
  it { is_expected.to be_able_to(:admin, mirakl_order_line_reimbursement) }

  it { is_expected.to be_able_to(:read, mirakl_offer) }
  it { is_expected.to be_able_to(:admin, mirakl_offer) }

  it { is_expected.to be_able_to(:read, mirakl_shop) }
  it { is_expected.to be_able_to(:admin, mirakl_shop) }
end

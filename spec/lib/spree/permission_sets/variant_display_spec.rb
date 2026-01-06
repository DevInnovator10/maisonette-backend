# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Spree::PermissionSets::VariantDisplay do
  subject { ability }

  let(:ability) { Spree::Ability.new(user) }
  let(:user) { nil }
  let(:variant) { Spree::Variant.new }
  let(:price) { Spree::Variant.new }
  let(:sale_price) { Spree::Variant.new }

  before do
    described_class.new(ability).activate!
  end

  it { is_expected.to be_able_to(:read, variant) }
  it { is_expected.to be_able_to(:edit, variant) }
  it { is_expected.to be_able_to(:admin, variant) }

  it { is_expected.to be_able_to(:read, price) }
  it { is_expected.to be_able_to(:admin, price) }

  it { is_expected.to be_able_to(:read, sale_price) }
  it { is_expected.to be_able_to(:admin, sale_price) }
end

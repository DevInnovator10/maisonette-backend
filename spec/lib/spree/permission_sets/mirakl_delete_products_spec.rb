# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Spree::PermissionSets::MiraklDeleteProducts do
  subject { ability }

  let(:ability) { Spree::Ability.new(user) }
  let(:user) { nil }

  before do
    described_class.new(ability).activate!
  end

  it { is_expected.to be_able_to(:read, :mirakl_menu) }
  it { is_expected.to be_able_to(:destroy, :mirakl_products) }
end

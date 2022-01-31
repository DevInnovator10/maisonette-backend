# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Spree::PermissionSets::EasypostDisplay do
  subject { ability }

  let(:ability) { Spree::Ability.new(user) }
  let(:user) { nil }
  let(:resource) { Easypost::Tracker.new }

  before do
    described_class.new(ability).activate!
  end

  it { is_expected.to be_able_to(:read, resource) }
  it { is_expected.to be_able_to(:admin, resource) }
end

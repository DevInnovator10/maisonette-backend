# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Spree::PermissionSets::TaxonomyManagement do
  subject { ability }

  let(:ability) { Spree::Ability.new(user) }
  let(:user) { nil }
  let(:taxonomy) { Spree::Taxonomy.new }
  let(:taxon) { Spree::Taxon.new }

  before do
    described_class.new(ability).activate!
  end

  it { is_expected.to be_able_to(:manage, taxonomy) }
  it { is_expected.to be_able_to(:manage, taxon) }
end

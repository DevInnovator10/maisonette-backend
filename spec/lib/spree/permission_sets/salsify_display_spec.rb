# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Spree::PermissionSets::SalsifyDisplay do
  subject { ability }

  let(:ability) { Spree::Ability.new(user) }
  let(:user) { nil }
  let(:import) { Salsify::Import.new }
  let(:import_row) { Salsify::ImportRow.new }
  let(:mirakl_offer_export_job) { Salsify::MiraklOfferExportJob.new }
  let(:mirakl_product_export_job) { Salsify::MiraklProductExportJob.new }

  before do
    described_class.new(ability).activate!
  end

  it { is_expected.to be_able_to(:read, import) }
  it { is_expected.to be_able_to(:admin, import) }

  it { is_expected.to be_able_to(:read, import_row) }
  it { is_expected.to be_able_to(:admin, import_row) }

  it { is_expected.to be_able_to(:read, mirakl_offer_export_job) }
  it { is_expected.to be_able_to(:admin, mirakl_offer_export_job) }

  it { is_expected.to be_able_to(:read, mirakl_product_export_job) }
  it { is_expected.to be_able_to(:admin, mirakl_product_export_job) }
end

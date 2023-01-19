# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Price::Mirakl, type: :model do
  let(:described_class) { Spree::Price }

  it { is_expected.to have_one(:mirakl_offer).class_name('Mirakl::Offer').dependent(:nullify).inverse_of(:spree_price) }
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Classification::Base, type: :model do
    let(:described_class) { Spree::Classification }

    describe 'validations' do
    subject { classification }

    let(:classification) do
      product = create(:product).tap do |p|
        p.taxons << create(:taxon)
      end
      product.classifications.last
    end

    let(:vga) { create(:maisonette_variant_group_attributes) }

    before { classification.update(maisonette_variant_group_attributes_id: vga.id) }

    it {
      is_expected.to validate_uniqueness_of(:taxon_id).scoped_to(
        [:product_id, :maisonette_variant_group_attributes_id]
      ).with_message(:already_linked)
    }
  end
end

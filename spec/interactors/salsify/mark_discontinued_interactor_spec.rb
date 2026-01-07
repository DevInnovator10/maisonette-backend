# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::MarkDiscontinuedInteractor do
  describe '#call' do
    subject(:interactor) { described_class.call(action: action, row: row, pdp_variant_enabled: pdp_variant_enabled) }

    let(:price) { create(:price, offer_settings: offer_settings, variant: variant, vendor: offer_settings.vendor) }
    let(:offer_settings) { create(:offer_settings, vendor: vendor) }
    let(:stock_location) { create :stock_location }
    let(:vendor) { stock_location.vendor }
    let(:variant) { offer_settings.variant }
    let(:stock_item) { variant.stock_items.first }
    let(:product) { variant.product }
    let(:row) { JSON.parse(file_fixture('salsify/valid_data.json').read).first }
    let(:current_time) { Time.current.beginning_of_day }
    let(:pdp_variant_enabled) { false }

    before do
      price
      allow(Spree::OfferSettings).to receive(:find_by).and_return(offer_settings)
    end

    context 'when invalid context' do
      context 'when no row' do
        let(:row) { nil }
        let(:action) { 'PD' }

        it 'fails' do
          expect(interactor).to be_a_failure
          expect(interactor.messages).to eq "#{described_class.name} cannot discontinue without row"
        end
      end

      context 'when no action' do
        let(:action) { nil }

        it 'fails' do
          expect(interactor).to be_a_failure
          expect(interactor.messages).to eq "#{described_class.name} cannot discontinue without action value"
        end
      end
    end

    context 'when offer settings is not on db' do
      let(:action) { 'PD' }
      let(:variant) { nil }
      let(:offer_settings) { nil }
      let(:price) { nil }

      it 'fails' do
        expect(interactor).to be_a_failure

        expect(interactor.messages).to eq "#{described_class.name} - offer settings not found"
      end
    end

    context 'when action is PD' do
      let(:action) { 'PD' }

      it 'marks the product discontinue' do
        expect { interactor }.to change { product.reload.available_until }.from(nil).to(current_time)
      end
    end

    context 'when action is VD' do
      let(:action) { 'VD' }

      it 'discards the offer_settings' do
        expect { interactor }.to change { offer_settings.reload.discarded? }.to(true)
      end

      it 'discards the price' do
        expect { interactor }.to change { price.reload.discarded? }.to(true)
      end

      it 'discards the stock_item' do

        expect { interactor }.to change { stock_item.reload.discarded? }.to(true)
      end
    end

    context 'when product is unavailable and offer_settings and price are discarded' do
      subject { -> { interactor } }

      let(:offer_settings) { create(:offer_settings, discarded_at: Time.current.beginning_of_day) }
      let(:price) do
        create(:price, offer_settings: offer_settings, variant: variant, vendor: offer_settings.vendor).tap do |price|
          price.update(deleted_at: Time.current.beginning_of_day)
        end
      end
      let(:product) { variant.product.tap { |product| product.update(available_until: Time.current.beginning_of_day) } }

      context 'when action is U' do
        let(:action) { 'U' }

        before do
          product.update(available_until: Time.current.beginning_of_day)
        end

        it 'marks the product as not discontinue' do
          expect { interactor }.to change { product.reload.available_until }.to(nil)
        end

        it 'undiscard the offer settings' do
          expect { interactor }.to change { offer_settings.reload.discarded? }.from(true).to(false)
        end

        it 'undiscard the price' do
          expect { interactor }.to change { price.reload.discarded? }.from(true).to(false)
        end
      end
    end

    context 'when pdp is enabled' do
      let(:pdp_variant_enabled) { true }
      let(:vga) { create(:maisonette_variant_group_attributes) }

      before do
        vga.update(product_id: product.id)
        product.reload
      end

      context 'when action is PD' do
        let(:action) { 'PD' }

        it 'skips changing the available_until' do
          expect { interactor }.not_to(change { product.reload.available_until })
        end
      end

      context 'when action is VD' do
        let(:action) { 'VD' }

        it 'discards the offer_settings' do
          expect { interactor }.to change { offer_settings.reload.discarded? }.to(true)
        end
      end
    end
  end
end

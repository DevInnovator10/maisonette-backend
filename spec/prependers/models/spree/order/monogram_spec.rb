# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::Monogram, type: :model do
  let(:described_class) { Spree::Order }

  describe '#matching_monogram_details' do
    subject { line_item.order.matching_monogram_details(line_item, options) }

    let(:line_item) { build_stubbed :line_item }

    before do
      allow(line_item).to receive_messages(monogram: monogram)
    end

    context 'when there is no monogram on line item' do
      let(:monogram) { nil }

      context 'when there are no monogram attributes' do
        let(:options) { { monogram_attributes: nil } }

        it { is_expected.to be_truthy }
      end

      context 'when there are monogram attributes' do
        let(:options) { { monogram_attributes: true } }

        it { is_expected.to be_falsey }
      end
    end

    context 'when there is monogram on line item' do
      let(:monogram) { instance_double Spree::LineItemMonogram, text: text, customization: customization }
      let(:customization) { 'some customization' }
      let(:text) { 'monogram 1' }

      context 'when there are no monogram attributes' do
        let(:options) { { monogram_attributes: nil } }

        it { is_expected.to be_falsey }
      end

      context 'when there are monogram attributes' do
        let(:options) { { monogram_attributes: true } }

        context 'when the text is different' do
          let(:options) { { monogram_attributes: { text: 'monogram 2', customization: customization } } }

          it 'returns false' do
            is_expected.to be_falsey
          end
        end

        context 'when the customization is different' do
          let(:options) { { monogram_attributes: { text: text, customization: 'customization 2' } } }

          it 'returns false' do
            is_expected.to be_falsey
          end
        end

        context 'when the text and customization is the same' do
          let(:options) { { monogram_attributes: { text: text, customization: customization } } }

          it 'returns true' do
            is_expected.to be_truthy
          end
        end
      end
    end
  end
end

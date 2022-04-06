# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cartonization::ShipsAloneInteractor do
  include_context 'when cartonizing an order with line items'
  let(:interactor) { described_class.new(ships_alone_line_items: line_items, chosen_boxes: []) }
  let(:context) { interactor.context }

  context 'when successful' do
    before { interactor.call }

    context 'when there are no ships alone line items' do
      let(:line_items) { [] }

      before { allow(interactor).to receive(:parse_ships_alone).and_call_original }

      it 'is a success' do
        expect(context).to be_a_success
      end

      it 'does not add any chosen boxes' do
        expect(context.chosen_boxes).to be_empty
      end

      it 'does not parse any line items' do
        expect(interactor).not_to have_received(:parse_ships_alone)
      end
    end

    context 'with a single line item that ships alone' do
      let(:line_items) { Array.wrap(line_item1) }

      it 'is a success' do
        expect(context).to be_a_success
      end

      it 'returns the line_item in ships_alone_line_items' do
        expect(context.ships_alone_line_items).to contain_exactly(*line_items)
      end

      it 'adds the box dimensions to chosen_boxes' do
        expect(context.chosen_boxes).to contain_exactly(
          hash_including(
            length: li1_length.to_f, width: li1_width.to_f, height: li1_height.to_f, weight: li1_weight.to_f
          )
        )
      end
    end

    context 'with multiple line items that ship alone' do
      let(:line_items) { [line_item1, line_item2] }

      it 'is a success' do
        expect(context).to be_a_success
      end

      it 'returns the ships alone line_item in ships_alone_line_items' do
        expect(context.ships_alone_line_items).to contain_exactly(line_item1, line_item2)
      end

      it 'adds all line item box dimensions to chosen_boxes' do
        expect(context.chosen_boxes).to contain_exactly(
          hash_including(
            length: li1_length.to_f, width: li1_width.to_f, height: li1_height.to_f, weight: li1_weight.to_f
          ),
          hash_including(
            length: li2_length.to_f, width: li2_width.to_f, height: li2_height.to_f, weight: li2_weight.to_f
          )
        )
      end
    end

    context 'with a single ships alone item with multiple internal packages' do
      let(:line_items) { Array.wrap(line_item3) }
      let(:li3_quantity) { 1 }

      it 'is a success' do
        expect(context).to be_a_success
      end

      it 'adds all of the internal package dimensions to chosen_boxes' do
        expect(context.chosen_boxes).to contain_exactly(
          hash_including(
            length: li3a_length.to_f, width: li3a_width.to_f, height: li3a_height.to_f, weight: li3a_weight.to_f
          ),
          hash_including(
            length: li3b_length.to_f, width: li3b_width.to_f, height: li3b_height.to_f, weight: li3b_weight.to_f
          )
        )
      end

      context 'when the quantity is more than one' do
        let(:li3_quantity) { 2 }

        it 'adds all of the internal package dimensions to chosen_boxes' do
          expect(context.chosen_boxes).to contain_exactly(
            hash_including(
              length: li3a_length.to_f, width: li3a_width.to_f, height: li3a_height.to_f, weight: li3a_weight.to_f
            ),
            hash_including(
              length: li3b_length.to_f, width: li3b_width.to_f, height: li3b_height.to_f, weight: li3b_weight.to_f
            ),
            hash_including(
              length: li3a_length.to_f, width: li3a_width.to_f, height: li3a_height.to_f, weight: li3a_weight.to_f
            ),
            hash_including(
              length: li3b_length.to_f, width: li3b_width.to_f, height: li3b_height.to_f, weight: li3b_weight.to_f
            )
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cartonization::MailerInteractor do
  include_context 'when cartonizing an order with line items'

  let(:context) { interactor.context }
  let(:interactor) do
    described_class.new(chosen_boxes: [],
                        available_mailers: available_mailers,
                        cartonized_line_items: line_items,
                        ships_in_mailer: ships_in_mailer)
  end
  let(:available_mailers) { [mailer_name1, mailer_name2] }
  let(:line_items) { Array.wrap(line_item1) }
  let(:ships_in_mailer) { true }
  let(:mailer_name1) { 'mailer-10-8-3' }
  let(:mailer_name2) { 'mailer-16-16-8' }

  context 'when successful' do
    context 'when selecting an appropriate mailer' do
      def max_mailer_volume(name)
        name.split('-').last(3).map(&:to_f).reduce(:*)
      end

      context 'when the smallest mailer fits' do
        before do
          allow(interactor).to receive(:total_shipment_volume).and_return(max_mailer_volume(mailer_name1) - 1)
        end

        it 'selects the smallest mailer that fits the total volume of the shipment' do
          interactor.call
          expect(context.selected_mailer).to eq mailer_name1
        end

        it 'adds the mailer to the chosen_boxes' do
          expect { interactor.call }.to change(context.chosen_boxes, :length).by 1
          expect(context.chosen_boxes).to contain_exactly hash_including(name: mailer_name1)
        end
      end

      context 'when the max shipment volume is greater than the smallest mailer but smaller than the next largest' do
        before do
          allow(interactor).to receive(:total_shipment_volume).and_return(max_mailer_volume(mailer_name2) - 1)
        end

        it 'selects the next largest mailer' do
          interactor.call
          expect(context.selected_mailer).to eq mailer_name2
        end

        it 'adds the mailer to the chosen_boxes' do
          expect { interactor.call }.to change(context.chosen_boxes, :length).by 1
          expect(context.chosen_boxes).to contain_exactly hash_including(name: mailer_name2)
        end
      end

      context 'when the total shipment volume is greater than the largest mailer' do
        before do
          allow(interactor).to receive(:total_shipment_volume).and_return(max_mailer_volume(mailer_name2) + 1)
        end

        it 'does not select a mailer' do
          interactor.call
          expect(context.selected_mailer).to be_nil
        end

        it 'sets ships in mailer to false' do
          interactor.call
          expect(context.ships_in_mailer).to be false
        end

        it 'does not generate a chosen box' do
          expect { interactor.call }.not_to change(context.chosen_boxes, :length)
        end
      end
    end

    context 'when setting the dimensions of the chosen box' do
      let(:line_items) { Array.wrap(line_item1) }

      context 'when the dimensional weight is greater than the total shipment weight' do
        let(:li1_length) { '12.5' }
        let(:li1_height) { '2.5' }
        let(:li1_width) { '4' }
        let(:li1_weight) { '0.1' }
        let(:li1_quantity) { 1 }

        before { interactor.call }

        it 'sets dimensions as the cubed root of the total shipment volume' do
          total_shipment_volume = li1_length.to_f * li1_height.to_f * li1_width.to_f * li1_quantity
          dim = Math.cbrt(total_shipment_volume)

          expect(context.chosen_boxes).to contain_exactly(
            hash_including(name: mailer_name1, length: dim, height: dim, width: dim)
          )
        end

        it 'sets the weight as the total_shipment weight' do
          total_shipment_weight = li1_quantity * li1_weight.to_f
          expect(context.chosen_boxes).to contain_exactly(hash_including(weight: total_shipment_weight))
        end
      end

      context 'when the dimensional weight is less than the total shipment weight' do
        let(:li1_length) { '1' }
        let(:li1_height) { '1' }
        let(:li1_width) { '1' }
        let(:li1_weight) { '3' }
        let(:li1_quantity) { 1 }

        before { interactor.call }

        it 'sets dimensions as the cubed root of dimensional weight calculated with the total shipment weight' do
          total_shipment_weight = li1_quantity * li1_weight.to_f
          rounded_dim = (Math.cbrt(total_shipment_weight * 166) * 4).ceil / 4

          expect(context.chosen_boxes).to contain_exactly(
            hash_including(name: mailer_name1, length: rounded_dim, height: rounded_dim, width: rounded_dim)
          )
        end

        it 'sets the weight as the total_shipment weight' do
          total_shipment_weight = li1_quantity * li1_weight.to_f
          expect(context.chosen_boxes).to contain_exactly(hash_including(weight: total_shipment_weight))
        end
      end
    end

    context 'when ships_in_mailer is false' do
      let(:ships_in_mailer) { false }
      let(:line_items) { Array.wrap(line_item1) }

      context 'when there are available mailers' do
        let(:available_mailers) { %w[mailer-10-8-3 mailer-16-16-8] }

        it 'is a success' do
          interactor.call
          expect(context).to be_a_success
        end

        it 'does not add to chosen_boxes' do
          expect { interactor.call }.not_to change(context.chosen_boxes, :length)
        end
      end
    end

    context 'when cartonized_line_items is empty' do
      let(:ships_in_mailer) { true }
      let(:line_items) { [] }

      context 'when there are available mailers' do
        let(:available_mailers) { %w[mailer-10-8-3 mailer-16-16-8] }

        before { allow(interactor).to receive(:generate_mailer_dimensions) }

        it 'is a success' do
          interactor.call
          expect(context).to be_a_success
        end

        it 'does not call paccurate' do
          expect { interactor.call }.not_to change(context.chosen_boxes, :length)
          expect(interactor).not_to have_received(:generate_mailer_dimensions)
        end
      end
    end
  end

  describe '#total_shipment_volume' do
    subject(:calculation) { interactor.send(:total_shipment_volume) }

    let(:interactor) { described_class.new(cartonized_line_items: line_items) }
    let(:line_items) { Array.wrap(line_item1) }

    it 'is the product of Length x Width x Height x Line Item Quantity' do
      expect(calculation).to eq(li1_length.to_f * li1_width.to_f * li1_height.to_f * li1_quantity)
    end

    context 'when the line item quantity is 2' do
      let(:li1_quantity) { 2 }

      it { is_expected.to eq(li1_length.to_f * li1_width.to_f * li1_height.to_f * li1_quantity) }
    end

    context 'when there are more than 1 internal package dimension sets' do
      let(:line_items) { Array.wrap(line_item3) }

      it {
        internal_package1_totals = li3a_length.to_f * li3a_width.to_f * li3a_height.to_f * li3_quantity
        internal_package2_totals = li3b_length.to_f * li3b_width.to_f * li3b_height.to_f * li3_quantity
        is_expected.to eq(internal_package1_totals + internal_package2_totals)
      }

      context 'when the line item quantity is 3' do
        let(:li3_quantity) { 3 }

        it {
          internal_package1_totals = li3a_length.to_f * li3a_width.to_f * li3a_height.to_f * li3_quantity
          internal_package2_totals = li3b_length.to_f * li3b_width.to_f * li3b_height.to_f * li3_quantity
          is_expected.to eq(internal_package1_totals + internal_package2_totals)
        }
      end
    end

    context 'when there are multiple line items' do
      let(:line_items) { [line_item1, line_item2] }

      it {
        line_item1_totals = li1_length.to_f * li1_width.to_f * li1_height.to_f * li1_quantity
        line_item2_totals = li2_length.to_f * li2_width.to_f * li2_height.to_f * li2_quantity
        is_expected.to eq(line_item1_totals + line_item2_totals)
      }
    end
  end

  describe '#total_shipment_weight' do
    subject(:calculation) { interactor.send(:total_shipment_weight) }

    let(:interactor) { described_class.new(cartonized_line_items: line_items) }
    let(:line_items) { Array.wrap(line_item1) }

    it 'is the product of weight x line item quantity' do
      expect(calculation).to eq(li1_quantity * li1_weight.to_f)
    end

    context 'when the line item quantity increases' do
      let(:li1_quantity) { 2 }

      it { is_expected.to eq(li1_quantity * li1_weight.to_f) }
    end

    context 'when there are multiple line items' do
      let(:line_items) { [line_item1, line_item2] }

      it { is_expected.to eq(li1_quantity * li1_weight.to_f + li2_quantity * li2_weight.to_f) }
    end

    context 'when there are multiple line_items with multiple internal packages' do
      let(:line_items) { [line_item1, line_item3] }
      let(:li3_quantity) { 3 }

      it {
        li1_totals = li1_quantity * li1_weight.to_f
        li3_totals = li3_quantity * li3a_weight.to_f + li3_quantity * li3b_weight.to_f
        is_expected.to eq(li1_totals + li3_totals)
      }
    end
  end
end

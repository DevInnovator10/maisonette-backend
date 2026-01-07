# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cartonization::PaccurateInteractor, :vcr do
  include_context 'when cartonizing an order with line items'

  let(:context) { interactor.context }

  let(:interactor) do
    described_class.new(
      ships_in_mailer: ships_in_mailer, cartonized_line_items: line_items,
      available_box_sizes: box_sizes, chosen_boxes: []
    )
  end

  let(:ships_in_mailer) { false }
  let(:line_items) { Array.wrap(line_item1) }

  let(:box_sizes) { Array.wrap(box_with_weight) }
  let(:box_with_weight) { 'fixed-16-10-12-40' }
  let(:box_without_weight) { 'fixed-24-10-16' }
  let(:box_nothing_fits_in) { 'fixed-1-1-1' }
  let(:box_with_weight_payload) do
    { 'name' => box_with_weight, 'weightMax' => 40.0, 'dimensions' => { 'x' => 16.0, 'y' => 10.0, 'z' => 12.0 } }
  end
  let(:box_without_weight_payload) do
    { 'name' => box_without_weight, 'weightMax' => 150.0, 'dimensions' => { 'x' => 24.0, 'y' => 10.0, 'z' => 16.0 } }
  end

  let(:line_item1_payload) do
    { 'refId' => 1,
      'weight' => li1_weight.to_f,
      'dimensions' => { 'x' => li1_length.to_f, 'y' => li1_height.to_f, 'z' => li1_width.to_f },
      'quantity' => line_item1.quantity }
  end
  let(:line_item2_payload) do
    { 'refId' => 1,
      'weight' => li2_weight.to_f,
      'dimensions' => { 'x' => li2_length.to_f, 'y' => li2_height.to_f, 'z' => li2_width.to_f },
      'quantity' => line_item2.quantity }
  end
  let(:line_item3_payload) do
    [
      { 'refId' => 2,
        'weight' => li3a_weight.to_f,
        'dimensions' => { 'x' => li3a_length.to_f, 'y' => li3a_height.to_f, 'z' => li3a_width.to_f },
        'quantity' => line_item3.quantity },
      { 'refId' => 3,
        'weight' => li3b_weight.to_f,
        'dimensions' => { 'x' => li3b_length.to_f, 'y' => li3b_height.to_f, 'z' => li3b_width.to_f },
        'quantity' => line_item3.quantity },
    ]
  end

  before { allow(Maisonette::Config).to receive(:fetch).with('paccurate.api_key').and_return(true) }

  context 'when successful' do
    before do
      allow(Paccurate::Api).to receive(:pack).and_call_original
      allow(interactor).to receive(:call_paccurate).and_call_original
      interactor.call
    end

    it 'is a success' do
      expect(context).to be_a_success
    end

    it 'calls paccurate' do
      expect(Paccurate::Api).to have_received(:pack)
    end

    it 'uses the default paccurate options' do
      expect(Paccurate::Api).to have_received(:pack).with(
        hash_including('boxTypeChoiceGoal' => 'most-items', 'includeScripts' => false)
      )
    end

    context 'when ships in mailer is true' do
      let(:ships_in_mailer) { true }

      it 'does not call paccurate' do
        expect(interactor).not_to have_received(:call_paccurate)
      end
    end

    context 'when cartonized_line_items is empty' do
      let(:ships_in_mailer) { false }
      let(:line_items) { [] }

      it 'does not call paccurate' do
        expect(interactor).not_to have_received(:call_paccurate)
      end
    end

    context 'when a vendor has a single box' do
      it 'sends the provided box dimensions to paccurate' do
        expect(Paccurate::Api).to have_received(:pack).with(
          hash_including('boxTypes' => Array.wrap(box_with_weight_payload))
        )
      end

      context 'when the vendor boxes do not include the weight' do
        let(:box_sizes) { Array.wrap(box_without_weight) }

        it 'uses the default 150 weight' do
          expect(Paccurate::Api).to have_received(:pack).with(
            hash_including('boxTypes' => Array.wrap(box_without_weight_payload))
          )
        end
      end
    end

    context 'when a vendor has multiple boxes' do
      let(:box_sizes) { [box_with_weight, box_without_weight] }

      it 'sends the provided box dimensions to paccurate' do
        expect(Paccurate::Api).to have_received(:pack).with(
          hash_including('boxTypes' => [box_with_weight_payload, box_without_weight_payload])
        )
      end
    end

    context 'when cartonizing an item with a single internal package' do
      it 'sends paccurate the correct item dimensions with values as floats' do
        expect(Paccurate::Api).to have_received(:pack).with hash_including('itemSets' => Array.wrap(line_item1_payload))
      end

      context 'when cartonizing an item with multiple internal packages' do
        let(:line_items) { [line_item1, line_item3] }

        it 'sends paccurate the correct item dimensions with values as floats' do
          expect(Paccurate::Api).to have_received(:pack).with(
            hash_including('itemSets' => [line_item1_payload, line_item3_payload].flatten)
          )
        end
      end
    end

    context 'when choosing a box' do
      context 'when there is a box that fits the item' do
        let(:box_sizes) { Array.wrap(box_with_weight) }

        it 'adds the box to chosen_boxes' do
          expect(context.chosen_boxes).to match_array(
            hash_including(name: 'fixed-16-10-12-40', weight: li1_weight.to_i, length: 16, width: 12, height: 10)
          )
        end

        context 'when the weight returned by paccurate is longer than 2 decimal places' do
          let(:li1_weight) { '4.1234' }

          it 'rounds the weight to 2 decimals' do
            expect(context.chosen_boxes).to match_array(
              hash_including(name: 'fixed-16-10-12-40', weight: 4.12, length: 16, width: 12, height: 10)
            )
          end
        end
      end

      context 'when there are no chosen boxes' do
        let(:box_sizes) { Array.wrap(box_nothing_fits_in) }
        let(:line_items) { [line_item1, line_item2] }

        it 'returns the largest box a vendor has' do
          expect(context.chosen_boxes).to match_array(
            hash_including(name: box_nothing_fits_in, length: 1.0, width: 1.0, height: 1.0)
          )
        end

        it 'sets the weight to the sum of the line items' do
          line_item1_weight = line_item1.internal_package_dimensions.map { |_k, dims| dims['weight'].to_f }.reduce(:+)
          line_item2_weight = line_item2.internal_package_dimensions.map { |_k, dims| dims['weight'].to_f }.reduce(:+)

          expect(context.chosen_boxes.first[:weight]).to eq(
            (line_item1_weight * li1_quantity) + (line_item2_weight * li2_quantity)
          )
        end

        context 'when the weight of the line items has a large float' do
          let(:line_items) { [line_item1] }
          let(:li1_weight) { '4.111111111111111' }

          it 'rounds the weight to two digits' do
            expect(context.chosen_boxes.first[:weight]).to eq li1_weight.to_f.round(2)
          end
        end

        context 'when the combined leftover weight exceeds 150' do
          let(:li2_weight) { 151 }

          it 'sets the weight to 150' do
            expect(context.chosen_boxes.first[:weight]).to eq 150
          end
        end
      end
    end
  end

  context 'when it is a failure' do
    let(:context) do
      described_class.call(
        cartonized_line_items: line_items, chosen_boxes: [], ships_in_mailer: false, available_box_sizes: box_sizes,
        mirakl_shop: mirakl_shop, mirakl_order: mirakl_order
      )
    end
    let(:exception) { Paccurate::Api::Error.new }
    let(:mirakl_shop) { instance_double Mirakl::Shop, shop_id: 1 }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 1 }

    before do
      allow(Paccurate::Api).to receive(:pack).and_return false
    end

    context 'when paccurare api key is false' do
      before do
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(Maisonette::Config).to receive(:fetch).with('paccurate.api_key').and_return(false)
      end

      it 'is a failure' do
        expect(context).to be_a_failure
        expect(Sentry).to have_received(:capture_exception_with_message)
      end
    end

    context 'when the paccurate API returns a failure' do
      it 'is a failure' do
        expect(context).to be_a_failure
      end

      it 'has the correct message' do
        expect(context.message).to eq 'Paccurate API failure'
      end

      it 'sets the chosen box to nil' do
        expect { context }.not_to change(context.chosen_boxes, :length)
      end
    end

    context 'when the paccurate API raise a Paccurate::Api::Error' do
      let(:paccurate_error) { 'Paccurate API failure, code: 422' }
      let(:exception) { Paccurate::Api::Error.new(paccurate_error) }

      before do
        allow(Paccurate::Api).to receive(:pack).and_raise(Paccurate::Api::Error.new(paccurate_error))
        allow(Sentry).to receive(:capture_exception_with_message)
      end

      it 'notifies Sentry' do
        expect(context).to be_a_failure
        expect(Sentry).to have_received(:capture_exception_with_message)
      end
    end

    context 'when there are no box sizes available' do
      let(:box_sizes) { [] }

      before do
        allow(Rails.logger).to receive(:error).and_call_original
      end

      it 'logs the error' do
        expect(context).to be_a_failure
        expect(Rails.logger).to have_received(:error).with('Missing mirakl shop box sizes')
      end
    end
  end
end

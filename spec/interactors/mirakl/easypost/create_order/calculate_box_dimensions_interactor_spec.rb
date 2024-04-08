# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::CreateOrder::CalculateBoxDimensionsInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) do
      instance_double Mirakl::Order, logistic_order_id: 'R123-A', mirakl_payload: { 'shop_id' => shop_id }
    end
    let(:mirakl_shop) { instance_double Mirakl::Shop, shop_id: shop_id, cartonize_shipments: cartonize_shipments }
    let(:shop_id) { rand(10_000).to_s }
    let(:cartonize_shipments) { false }

    let(:order_level_dimensions) { [{ name: 'mailer-16-16-10', width: 5.6, length: 6.4, height: 2.5, weight: 3 }] }
    let(:multi_box_item_dimensions) do
      [{ width: 5.6, length: 6.4, height: 2.5, weight: 3 },
       { width: 6.5, length: 4.6, height: 5.2, weight: 2 }]
    end
    let(:largest_item_dimensions) { { width: 15.6, length: 16.4, height: 12.5, weight: 13 } }
    let(:multiple_box_item) {}
    let(:order_level_dimensions?) {}
    let(:build_dimensions) { order_level_dimensions }
    let(:cartonization) do
      double Interactor::Context, # rubocop:disable RSpec/VerifiedDoubles
             success?: cartonization_success,
             chosen_boxes: cartonization_boxes
    end
    let(:cartonization_success) { true }
    let(:cartonization_boxes) { order_level_dimensions }

    before do
      allow(Mirakl::Shop).to receive(:find_by).with(shop_id: shop_id).and_return mirakl_shop
    end

    context 'when cartonizing shipments' do
      let(:cartonize_shipments) { true }

      before do
        allow(Cartonization::PackShipmentOrganizer).to(
          receive(:call).with(mirakl_order: mirakl_order, mirakl_shop: mirakl_shop)
        )
        allow(interactor).to receive_messages(order_level_dimensions?: false, validate_box_dimensions: true)
      end

      it 'calls the interactor with the mirakl order and mirakl shop' do
        interactor.call
        expect(Mirakl::Shop).to have_received(:find_by).with(shop_id: shop_id)
        expect(Cartonization::PackShipmentOrganizer).to(
          have_received(:call).with(mirakl_order: mirakl_order, mirakl_shop: mirakl_shop)
        )
      end

      context 'when cartonization is a failure' do
        let(:cartonization_context) do
          double 'Cartonization::PackShipmentOrganizer', success?: false # rubocop:disable RSpec/VerifiedDoubles
        end

        before do
          allow(interactor).to receive(:cartonization).and_return cartonization_context
          allow(interactor).to receive(:multiple_box_item).and_return false
          allow(interactor).to receive(:largest_item_dimensions).and_call_original
          interactor.call
        end

        it 'calls the legacy methods for determining box size' do
          expect(interactor).to have_received(:multiple_box_item)
          expect(interactor).to have_received(:largest_item_dimensions)
        end
      end
    end

    context 'when it is successful' do
      before do
        allow(interactor).to receive_messages(order_level_dimensions?: order_level_dimensions?,
                                              order_level_dimensions: order_level_dimensions,
                                              multiple_box_item: multiple_box_item,
                                              multi_box_item_dimensions: multi_box_item_dimensions,
                                              largest_item_dimensions: largest_item_dimensions,
                                              validate_box_dimensions: true,
                                              cartonization: cartonization)
        allow(interactor).to receive(:rescue_and_capture).and_call_original
        allow(Sentry).to receive(:capture_exception_with_message)
        interactor.call
      end

      it 'calls validate_box_dimensions' do
        expect(interactor).to have_received(:validate_box_dimensions)
      end

      context 'when the mirakl order has order level dimensions' do
        let(:order_level_dimensions?) { true }

        it 'will not update mirakl' do
          expect(interactor.context.update_mirakl).to eq false
        end

        it 'assigns context.boxes with order level dimensions' do
          expect(interactor.context.boxes).to eq order_level_dimensions
        end
      end

      context 'when the mirakl has order LINE level dimensions' do
        let(:order_level_dimensions?) { false }

        it 'will update mirakl' do
          expect(interactor.context.update_mirakl).to eq true
        end

        context 'when the order has a line with multiple boxes' do
          let(:multiple_box_item) { true }

          it 'assigns context.boxes with dimensions from multi-box item' do
            expect(interactor.context.boxes).to eq multi_box_item_dimensions
          end
        end

        context 'when the order does not have a multi-box item' do

          let(:multiple_boxes?) { false }

          it 'assigns context.boxes with dimensions from the largest item' do
            expect(interactor.context.boxes).to eq [largest_item_dimensions]
          end
        end
      end

      context 'when there are too many boxes returned by cartonization' do
        let(:cartonize_shipments) { true }
        let(:order_level_dimensions?) { false }
        let(:cartonization_boxes) { order_level_dimensions * (max_box_quantity + 1) }
        let(:max_box_quantity) { MIRAKL_DATA[:boxes].length }
        let(:error_message) { "#{mirakl_order.logistic_order_id}: Maximum box quantity exceeded for cartonization" }

        it 'is a success' do
          expect(interactor.context).to be_a_success
        end

        it 'sets the correct error message' do
          expect(interactor.context.error_message).to eq error_message
        end

        it 'notifies Sentry with max box error' do
          expect(interactor).to have_received(:rescue_and_capture).with(
            instance_of(Mirakl::Easypost::MaxBoxQuantityExceededError),
            error_details: error_message,
            extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id, details: error_message }
          )
          expect(Sentry).to have_received(:capture_exception_with_message)
        end

        it 'limits the boxes to the maximum allowed' do
          expect(interactor.context.boxes.length).to eq max_box_quantity
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }
      let(:error_message) do
        "#{mirakl_order.logistic_order_id}: Missing or Invalid box dimensions - #{exception.message}"
      end

      before do
        allow(interactor).to receive(:rescue_and_capture).and_call_original
        allow(Sentry).to receive(:capture_exception_with_message)
      end

      context 'when it fails due to a generic error' do
        before do
          allow(interactor).to receive(:order_level_dimensions?).and_raise(exception)
          interactor.call
        end

        it 'rescues and captures the exception' do
          expect(interactor).to(
            have_received(:rescue_and_capture).with(exception,
                                                    error_details: 'Missing or Invalid box dimensions',
                                                    extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id,
                                                             details: exception.message })
          )
        end

        it 'saves the error_message to context' do
          expect(interactor.context.error_message).to eq error_message
        end

        it 'notifies Sentry' do
          expect(Sentry).to have_received(:capture_exception_with_message)
        end
      end

      context 'when it errors due to invalid dimensions' do
        let(:order_level_dimensions) { { width: 0 } }

        before do
          allow(interactor).to receive_messages(
            order_level_dimensions?: true,
            order_level_dimensions: Array.wrap(order_level_dimensions),
            ensure_box_quantities: nil
          )
          interactor.call
        end

        it 'throws the correct exception' do
          expect(interactor).to have_received(:rescue_and_capture).with(
            instance_of(Mirakl::Easypost::InvalidDimensionError),
            error_details: 'Missing or Invalid box dimensions',
            extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id, details: 'width cannot be zero' }
          )
        end

        it 'notifies Sentry' do
          expect(Sentry).to have_received(:capture_exception_with_message)
        end

        context 'when there is a name attribute' do
          let(:order_level_dimensions) { { name: 'mailer-16-16-10' } }

          it 'does not throw an error' do
            expect(Sentry).not_to have_received(:capture_exception_with_message)
          end
        end
      end
    end
  end

  describe '#order_level_dimensions?' do
    subject(:order_level_dimensions) { interactor.send(:order_level_dimensions?) }

    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, mirakl_payload: mirakl_payload }
    let(:mirakl_payload) do
      { 'order_additional_fields' => [additional_field_weight,
                                      additional_field_height,
                                      additional_field_width,
                                      additional_field_length].compact }
    end
    let(:box1_weight_label) { MIRAKL_DATA[:boxes][:box1][:weight] }
    let(:box1_height_label) { MIRAKL_DATA[:boxes][:box1][:height] }
    let(:box1_width_label) { MIRAKL_DATA[:boxes][:box1][:width] }
    let(:box1_length_label) { MIRAKL_DATA[:boxes][:box1][:length] }

    context 'when the order has 4 order level box dimensions' do
      let(:additional_field_weight) { { 'code' => box1_weight_label, 'value' => '5' } }
      let(:additional_field_height) { { 'code' => box1_height_label, 'value' => '5' } }
      let(:additional_field_width) { { 'code' => box1_width_label, 'value' => '5' } }
      let(:additional_field_length) { { 'code' => box1_length_label, 'value' => '5' } }

      it 'returns true' do
        expect(order_level_dimensions).to be_truthy
      end
    end

    context 'when the order does not have 4 order level box dimensions' do
      let(:additional_field_weight) { { 'code' => box1_weight_label, 'value' => '5' } }
      let(:additional_field_height) { { 'code' => box1_height_label, 'value' => '5' } }
      let(:additional_field_width) {}
      let(:additional_field_length) {}

      it 'returns false' do
        expect(order_level_dimensions).to be_falsey
      end
    end
  end

  describe '#multi_box_item_dimensions' do
    subject(:multi_box_item_dimensions) { interactor.send(:multi_box_item_dimensions) }

    let(:interactor) { described_class.new }
    let(:multiple_box_item) { 'fields from multi box item' }
    let(:multiple_box_dimensions) do
      [{ width: 5.6, length: 6.4, height: 2.5, weight: 3 },
       { width: 6.5, length: 4.6, height: 5.2, weight: 2 }]
    end

    before do
      allow(interactor).to receive_messages(multiple_box_item: multiple_box_item,
                                            dimensions_from_payload_fields: multiple_box_dimensions)

      multi_box_item_dimensions
    end

    it 'calls dimensions_from_payload_fields with multi_box_item fields' do
      expect(interactor).to have_received(:dimensions_from_payload_fields).with(multiple_box_item)
    end

    it 'returns dimensions_from_payload_fields' do
      expect(multi_box_item_dimensions).to eq multiple_box_dimensions
    end
  end

  describe '#multiple_box_item' do
    subject(:multiple_box_item) { interactor.send(:multiple_box_item) }

    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { build_stubbed :mirakl_order, order_lines_payload: order_lines_payload }
    let(:number_of_boxes_label) { MIRAKL_DATA[:order_line][:additional_fields][:number_of_boxes] }
    let(:order_lines_payload) do
      [{ 'order_line_additional_fields' => item_missing_number_of_boxes_field },
       { 'order_line_additional_fields' => single_box_item_fields },
       { 'order_line_additional_fields' => multiple_box_item_fields }]
    end
    let(:item_missing_number_of_boxes_field) { [{ 'code' => 'some field', 'value' => 'some value' }] }
    let(:single_box_item_fields) { [{ 'code' => number_of_boxes_label, 'value' => 1 }] }
    let(:multiple_box_item_fields) { [{ 'code' => number_of_boxes_label, 'value' => 2 }] }

    it 'returns additional fields for a multi-box item' do
      expect(multiple_box_item).to eq multiple_box_item_fields
    end

    context 'when no multiple box item if found' do
      let(:order_lines_payload) do
        [{ 'order_line_additional_fields' => item_missing_number_of_boxes_field },
         { 'order_line_additional_fields' => single_box_item_fields }]
      end

      it 'returns false' do
        expect(multiple_box_item).to be_falsey
      end
    end
  end

  describe '#largest_item_dimensions' do
    subject(:largest_item_dimensions) { interactor.send(:largest_item_dimensions) }

    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { build_stubbed :mirakl_order, order_lines_payload: order_lines_payload }

    context 'when there are 4 order line addition fields box dimensions' do
      let(:order_lines_payload) { [order_line_1, order_line_2] }
      let(:largest_item_dimensions_hash) { { length: '20.0', width: '30.4', height: '50.6', weight: '26.2' } }
      let(:order_line_1) do
        { 'order_line_additional_fields' =>
            [{ 'code' => 'box1-packaged-height', 'type' => 'NUMERIC', 'value' => '5.6' },
             { 'code' => 'box1-packaged-length', 'type' => 'NUMERIC', 'value' => '2.0' },
             { 'code' => 'box1-packaged-weight', 'type' => 'NUMERIC', 'value' => '6.2' },
             { 'code' => 'box1-packaged-width-depth', 'type' => 'NUMERIC', 'value' => '3.4' }] }
      end
      let(:order_line_2) do
        { 'order_line_additional_fields' =>
            [{ 'code' => 'box1-packaged-height', 'type' => 'NUMERIC', 'value' => '50.6' },
             { 'code' => 'box1-packaged-length', 'type' => 'NUMERIC', 'value' => '20.0' },
             { 'code' => 'box1-packaged-weight', 'type' => 'NUMERIC', 'value' => '26.2' },
             { 'code' => 'box1-packaged-width-depth', 'type' => 'NUMERIC', 'value' => '30.4' }] }
      end

      it 'returns the largest items dimensions' do
        expect(largest_item_dimensions).to eq largest_item_dimensions_hash
      end
    end

    context 'when there are less that 4 order line addition fields box dimensions' do
      let(:order_lines_payload) { [order_line_1] }
      let(:order_line_1) do
        { 'order_line_additional_fields' =>
            [{ 'code' => 'box1-packaged-height', 'type' => 'NUMERIC', 'value' => '5.6' },
             { 'code' => 'box1-packaged-width-depth', 'type' => 'NUMERIC', 'value' => '3.4' }] }
      end
      let(:largest_item_dimensions_hash) { { length: '10.0', width: '15.2', height: '25.3', weight: '13.1' } }

      before do
        allow(interactor).to receive(:fetch_largest_product_dimensions).and_return(largest_item_dimensions_hash)

        largest_item_dimensions
      end

      it 'calls fetch_largest_product_dimensions' do
        expect(interactor).to have_received(:fetch_largest_product_dimensions)
      end

      it 'returns the largest product dimensions' do
        expect(largest_item_dimensions).to eq largest_item_dimensions_hash
      end
    end
  end

  describe '#fetch_largest_product_dimensions' do
    subject(:fetch_largest_product_dimensions) { interactor.send(:fetch_largest_product_dimensions) }

    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, order_lines: order_lines }
    let(:order_lines) { [order_line1, order_line2] }
    let(:order_line1) { instance_double Mirakl::OrderLine, line_item: line_item1 }
    let(:order_line2) { instance_double Mirakl::OrderLine, line_item: line_item2 }
    let(:line_item1) { instance_double Spree::LineItem, product: product1 }
    let(:line_item2) { instance_double Spree::LineItem, product: product2 }
    let(:product1) { instance_double Spree::Product, box_properties: box_properties1 }
    let(:product2) { instance_double Spree::Product, box_properties: box_properties2 }
    let(:box_properties1) do
      [['Box1 Packaged Weight', '5lbs'],
       ['Box1 Packaged Length', '12'],
       ['Box1 Packaged Width/Depth', '8'],
       ['Box1 Packaged Height', '3']]
    end
    let(:box_properties2) do
      [['Box1 Packaged Weight', '10lbs'],
       ['Box1 Packaged Length', '24'],
       ['Box1 Packaged Width/Depth', '16'],
       ['Box1 Packaged Height', '6']]
    end
    let(:largest_product_dimensions_hash) { { length: 24.0, width: 16.0, height: 6.0, weight: 10.0 } }

    it 'returns the largest product dimensions' do
      expect(fetch_largest_product_dimensions).to eq largest_product_dimensions_hash
    end
  end

  describe '#validate_box_dimensions' do
    subject(:validate_box_dimensions) { interactor.send :validate_box_dimensions }

    let(:interactor) { described_class.new(boxes: boxes) }

    context 'when the box dimensions are all positive numbers' do
      let(:boxes) do
        [{ height: 1.1,
           weight: 2.2,
           length: 3.3,
           width: 4.4 }]
      end

      it 'does not raise an exception' do
        expect { validate_box_dimensions }.not_to raise_exception
      end
    end

    context 'when the box dimensions are strings' do
      let(:boxes) do
        [{ height: '1.1',
           weight: '2.2',
           length: '3.3',
           width: '4.4' }]
      end

      it 'does not raise an exception' do
        expect { validate_box_dimensions }.not_to raise_exception
      end
    end

    context 'when a box dimensions is zero' do
      let(:boxes) do
        [{ height: 0.0,
           weight: 2.2,
           length: 3.3,
           width: 4.4 }]
      end

      it 'does raise an exception' do
        expect { validate_box_dimensions }.to raise_exception(StandardError)
      end
    end
  end
end

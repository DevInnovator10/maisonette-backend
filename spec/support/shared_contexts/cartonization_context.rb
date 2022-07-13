# frozen_string_literal: true

RSpec.shared_context 'when cartonizing an order with line items' do
  let(:mirakl_shop) { instance_double Mirakl::Shop, box_sizes: box_sizes, name: 'Maisonette', shop_id: 1 }
  let(:box_sizes) { [] }

  let(:mirakl_order) { instance_double Mirakl::Order, shipment: shipment, logistic_order_id: 'M1234' }

  let(:shipment) { instance_double Spree::Shipment, line_items: shipment_line_items }
  let(:shipment_line_items) { [] }

  let(:line_item1) do
    instance_double Spree::LineItem, quantity: li1_quantity, internal_package_dimensions: li1_dimensions
  end
  let(:li1_quantity) { 1 }
  let(:li1_dimensions) do
    {
      internal_package1: { length: li1_length, height: li1_height, width: li1_width, weight: li1_weight }
    }.deep_stringify_keys
  end
  let(:li1_length) { '10' }
  let(:li1_width) { '7.1' }
  let(:li1_height) { '4' }
  let(:li1_weight) { '4' }

  let(:line_item2) do
    instance_double Spree::LineItem, quantity: li2_quantity, internal_package_dimensions: li2_dimensions
  end
  let(:li2_quantity) { 1 }
  let(:li2_dimensions) do
    {
      internal_package1: { length: li2_length, height: li2_height, width: li2_width, weight: li2_weight }
    }.deep_stringify_keys
  end
  let(:li2_length) { '16' }
  let(:li2_width) { '12.1' }
  let(:li2_height) { '32' }
  let(:li2_weight) { '10' }

  let(:line_item3) do
    instance_double Spree::LineItem, quantity: li3_quantity, internal_package_dimensions: li3_dimensions
  end
  let(:li3_quantity) { 1 }
  let(:li3_dimensions) do
    {
      internal_package1: { length: li3a_length, height: li3a_height, width: li3a_width, weight: li3a_weight },
      internal_package2: { length: li3b_length, height: li3b_height, width: li3b_width, weight: li3b_weight }
    }.deep_stringify_keys
  end
  let(:li3a_length) { '12' }
  let(:li3a_width) { '7' }
  let(:li3a_height) { '8' }
  let(:li3a_weight) { '4' }

  let(:li3b_length) { '10' }
  let(:li3b_width) { '10' }
  let(:li3b_height) { '10' }
  let(:li3b_weight) { '7' }
end

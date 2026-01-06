# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::OrderLevelDimensions, mirakl: true do
  let(:described_class) { FakeInteractor }

  describe '#order_level_dimensions' do
    subject(:order_level_dimensions) { interactor.send :order_level_dimensions }

    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, mirakl_payload: mirakl_payload }
    let(:mirakl_payload) { { 'order_additional_fields' => order_additional_fields } }
    let(:order_additional_fields) { 'foo' }
    let(:dimensions_from_payload_fields) { 1 }

    before do
      allow(interactor).to receive_messages(dimensions_from_payload_fields: dimensions_from_payload_fields)

      order_level_dimensions
    end

    it 'calls dimensions_from_payload_fields with order fields' do
      expect(interactor).to have_received(:dimensions_from_payload_fields).with(order_additional_fields)
    end

    it 'returns dimensions_from_payload_fields' do
      expect(order_level_dimensions).to eq dimensions_from_payload_fields
    end
  end

  describe '#dimensions_from_payload_fields' do
    subject(:order_level_dimensions) { interactor.send :dimensions_from_payload_fields, fields }

    let(:interactor) { described_class.new }
    let(:fields) do
      [{ 'code' => 'box1-packaged-weight', 'type' => 'NUMERIC', 'value' => '5.0' },
       { 'code' => 'box1-packaged-length', 'type' => 'NUMERIC', 'value' => '3.6' },
       { 'code' => 'box1-packaged-height', 'type' => 'NUMERIC', 'value' => '5.2' },
       { 'code' => 'box1-packaged-width-depth', 'type' => 'NUMERIC', 'value' => '2.5' },
       { 'code' => 'box2-packaged-weight', 'type' => 'NUMERIC', 'value' => '6.0' },
       { 'code' => 'box2-packaged-length', 'type' => 'NUMERIC', 'value' => '4.6' },
       { 'code' => 'box2-packaged-height', 'type' => 'NUMERIC', 'value' => '7.2' },
       { 'code' => 'box2-packaged-width-depth', 'type' => 'NUMERIC', 'value' => '5.4' }]
    end

    let(:box1) { { weight: 5.0, length: 3.6, height: 5.2, width: 2.5 } }
    let(:box2) { { weight: 6.0, length: 4.6, height: 7.2, width: 5.4 } }
    let(:boxes) { [box1, box2] }

    it 'returns a array of box dimensions' do
      expect(order_level_dimensions).to eq boxes
    end
  end
end

class FakeInteractor
  include Interactor
  include Mirakl::Easypost::OrderLevelDimensions
end

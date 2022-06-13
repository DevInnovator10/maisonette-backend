# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::CategorySynchronizationInteractor, mirakl: true do
  let(:interactor) { described_class.new }

  describe '#call' do
    let(:context) { interactor.run }
    let(:product_type) { create :taxonomy, name: 'Product Type' }
    let(:dresses) { create :taxon, parent: product_type.root, taxonomy: product_type, name: 'Dresses' }
    let(:shirts) { create :taxon, parent: product_type.root, taxonomy: product_type, name: 'Shirts' }
    let(:shoes) { create :taxon, parent: product_type.root, taxonomy: product_type, name: 'Shoes' }
    let(:csv_content) do
      [

        %w[category-code category-label parent-code update-delete],
        ['Dresses', 'Dresses', '', 'update'],
        ['Dresses Exclusives', 'Dresses Exclusives', '', 'update'],
        ['Shirts', 'Shirts', '', 'update'],
        ['Shirts Exclusives', 'Shirts Exclusives', '', 'update'],
        ['Shoes', 'Shoes', '', 'update'],
        ['Shoes Exclusives', 'Shoes Exclusives', '', 'update']
      ].map { |line| CSV.generate_line line }.join
    end

    before do
      allow(interactor).to receive(:post)
      allow(Mirakl::BinaryFileStringIO).to receive(:new).and_call_original
      dresses
      shirts
      shoes
    end

    context 'when it is successful' do
      before { context }

      it 'builds the payload correctly' do
        expect(Mirakl::BinaryFileStringIO).to have_received(:new).with(csv_content, 'product-category-synchros.csv')
      end

      it 'calls post to /categories/synchros with Binary String File' do
        expect(interactor).to(
          have_received(:post).with('categories/synchros', payload: { file: instance_of(Mirakl::BinaryFileStringIO) })
        )
      end
    end

    context 'when the product type taxonomy is missing' do
      before do
        allow(Spree::Taxonomy).to receive(:find_by)
        context
      end

      it 'is a failure' do
        expect(interactor.context).to be_a_failure
        expect(interactor.context.error).to eq 'Unable to find Product Type taxonomy'
      end

      it 'does not call mirakl' do
        expect(interactor).not_to have_received(:post)
      end
    end

    context 'when it throws a general error' do
      let(:exception) { StandardError.new 'foo' }

      before do
        allow(interactor).to receive(:post).and_raise(exception)
        allow(interactor).to receive(:rescue_and_capture)
        interactor.run
      end

      it 'calls #handle_rest_error' do
        expect(interactor).to have_received(:rescue_and_capture).with(
          exception, error_details: 'Unable to create Mirakl Product Synchro'
        )
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ImportProductImagesWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(1, variant_group_attributes_id) }

    let(:context) do
      double(Interactor::Context, failure?: false, messages: 'some messages') # rubocop:disable RSpec/VerifiedDoubles
    end
    let(:import_row) { build :salsify_import_row, :from_dev_file, state: :imported }
    let(:variant_group_attributes_id) { nil }

    before do
      allow(Salsify::ImportRow).to receive(:find).and_return(import_row)
      allow(Salsify::ImportProductImagesInteractor).to receive(:call).and_return(context)
    end

    it 'calls the product images and the clean up interactors' do
      perform
      expect(Salsify::ImportProductImagesInteractor).to have_received :call
    end
    it { expect { perform }.to change(import_row, :state).from('imported').to('completed') }

    context 'when variant_group_attributes_id is present' do
      let(:variant_group_attributes_id) { variant_group_attributes.id }
      let(:variant_group_attributes) do
        instance_double Maisonette::VariantGroupAttributes, id: 1
      end

      before do
        allow(Maisonette::VariantGroupAttributes).to receive(:find_by)
          .with(id: variant_group_attributes_id).and_return(variant_group_attributes)
      end

      it 'calls ImportProductImagesInteractor with variant_group_attributes' do
        perform
        expect(Salsify::ImportProductImagesInteractor).to have_received :call
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::UpdateVariantImagesWorker do
  it { expect { described_class.new.perform }.to raise_error(ArgumentError) }

  context 'with styles parameter' do
    subject(:perform) { described_class.new.perform(styles) }

    let(:batch_worker_class) { ::Maisonette::UpdateVariantImagesBatchWorker }
    let(:styles) { 'style1,style2,style3' }
    let(:variants_count) { 180 }

    before do
      allow(Spree::Variant).to receive(:count).and_return(variants_count)
      allow(batch_worker_class).to receive(:perform_async)
      perform
    end

    it 'calls the batch worker for each batch' do
      times = (variants_count / 50.0).ceil
      expect(batch_worker_class).to have_received(:perform_async).exactly(times).times
    end
  end
end

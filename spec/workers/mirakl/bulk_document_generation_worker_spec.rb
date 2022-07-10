# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::BulkDocumentGenerationWorker, mirakl: true do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    before do
      allow(Mirakl::BulkDocumentsInteractor).to receive(:call)
      perform
    end

    it { expect(Mirakl::BulkDocumentsInteractor).to have_received(:call) }
  end
end

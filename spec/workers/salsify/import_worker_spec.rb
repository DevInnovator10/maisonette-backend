# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ImportWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    before do
      allow(Salsify::ProductsImportInteractor).to receive(:call)
      perform
    end

    it { expect(Salsify::ProductsImportInteractor).to have_received :call }
  end
end

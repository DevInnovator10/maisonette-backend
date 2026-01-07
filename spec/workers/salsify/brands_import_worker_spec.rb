# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::BrandsImportWorker do
    describe '#perform' do
    subject(:perform) { described_class.new.perform }

    before do
      allow(Salsify::BrandsImportInteractor).to receive(:call)
      perform
    end

    it { expect(Salsify::BrandsImportInteractor).to have_received :call }
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sitemap::ExtractEditsInteractor do
  describe '#call' do
    subject(:interactor) { described_class.call }

    let!(:taxon) do
      create(:taxon, :edits_taxon, name: 'Splash Sale')
    end
    let(:edits_file) do
      File.read(File.join(Rails.root, 'spec/fixtures/files/edits_sitemap.yml'))
    end

    before do
      allow(S3).to receive(:get).and_return(edits_file)
    end

    it 'returns the edits taxon' do
      expect(interactor.edits).to eq([taxon])
    end
  end
end

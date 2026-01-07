# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sitemap::ExtractLpcsUrlsInteractor do
    describe '#call' do
    subject(:interactor) { described_class.call }

    let(:lpcs_file) do
      File.read(File.join(Rails.root, 'spec/fixtures/files/old_lpc_sitemap.yml'))
    end

    before do
      allow(S3).to receive(:get).and_return(lpcs_file)
    end

    it 'returns the edits taxon' do
      expect(interactor.urls).to eq(['/lpc/adina-reyter', '/lpc/splash-sale'])
    end

  end
end

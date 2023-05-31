# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxSvc::Client do
  let(:described_class) { TaxSvc }

  describe '#client' do
    subject(:client) { tax_svc.client }

    let(:tax_svc) { described_class.new }
    let(:account_number) { 'act-1234' }
    let(:license_key) { 'key-1234' }
    let(:environment) { 'test' }
    let(:avatax_client) { instance_double Avatax::Client }

    before do
      allow(Spree::Avatax::Config).to receive_messages(account: account_number,
                                                       license_key: license_key,
                                                       environment: environment)
      allow(Avatax::Client).to receive(:new) { avatax_client }

      client
    end

    it 'returns the client object' do
      expect(client).to eq avatax_client
    end

    it 'creates the Avatax::Client with configurations' do
      expect(Avatax::Client).to have_received(:new).with(username: account_number,
                                                         password: license_key,
                                                         env: environment,
                                                         headers: AVATAX_HEADERS)
    end
  end
end

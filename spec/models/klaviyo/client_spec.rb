# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Klaviyo::Client do
  subject(:client) { described_class.new(public_key: public_key, private_key: private_key) }

  let(:public_key) { nil }
  let(:private_key) { nil }

  let(:default_public_key) { 'default_public_key' }
  let(:default_private_key) { 'default_private_key' }

  let(:modules) { [Klaviyo::Basic::Identify, Klaviyo::Basic::Track] }

  before do
    allow(Maisonette::Config).to receive(:fetch).with('klaviyo.public_api_key').and_return default_public_key
    allow(Maisonette::Config).to receive(:fetch).with('klaviyo.private_api_key').and_return default_private_key
    client
  end

  it { expect(described_class.ancestors).to include(*modules) }

  it 'uses the default public api key if one is not provided' do
    expect(Maisonette::Config).to have_received(:fetch).with('klaviyo.public_api_key')
    expect(client.instance_variable_get(:@public_api_key)).to eq default_public_key
  end

  it 'uses the default private api key if one is not provided' do
    expect(Maisonette::Config).to have_received(:fetch).with('klaviyo.private_api_key')
    expect(client.instance_variable_get(:@private_api_key)).to eq default_private_key
  end

  context 'when providing a custom api keys' do
    let(:public_key) { 'user_provided_public_key' }
    let(:private_key) { 'user_provided_private_key' }

    it 'can use a custom private api key' do
      expect(Maisonette::Config).not_to have_received(:fetch)
      expect(client.instance_variable_get(:@private_api_key)).to eq private_key
    end

    it 'can use a custom public api key' do

      expect(Maisonette::Config).not_to have_received(:fetch)
      expect(client.instance_variable_get(:@public_api_key)).to eq public_key
    end
  end

  describe '#list' do
    subject(:list) { client.list(list_id) }

    let(:list_id) { nil }

    it { is_expected.to be_a Klaviyo::Client::Lists }

    it 'passes in the client' do
      expect(list.client).to eq client
    end

    it 'does not require a list_id' do
      expect(list.list_id).to be_nil
    end

    context 'when specifying a list' do
      let(:list_id) { 'list1' }

      it 'sets the list_id' do
        expect(list.list_id).to eq 'list1'
      end
    end
  end

  describe '#data_privacy' do
    subject(:data_privacy) { client.data_privacy }

    it { is_expected.to be_a Klaviyo::Client::DataPrivacy }

    it 'passes in the client' do
      expect(data_privacy.client).to eq client
    end
  end
end

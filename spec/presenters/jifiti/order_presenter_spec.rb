# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jifiti::OrderPresenter do
  describe '#jifiti?' do
    subject { described_class.new(order) }

    context 'when channel not is jifiti' do
      let(:order) { create(:order, channel: 'spree') }

      it { is_expected.not_to be_jifiti }
    end

    context 'when channel is jifiti' do
      let(:order) { create(:order, channel: 'jifiti') }

      it { is_expected.to be_jifiti }
    end
  end

  describe '#receiver_email' do
    subject { described_class.new(order).receiver_email }

    let(:order) do
      create(:order, special_instructions: "external_source: Jifiti Registry\r\n jifiti_receiver_email: user@email.com")
    end

    it { is_expected.to eq 'user@email.com' }

    context 'when special_instruction has more key/value' do
      let(:order) do
        create(:order, special_instructions: jifiti_instructions)
      end
      let(:jifiti_instructions) do
        "external_source: Jifiti Registry\r\n jifiti_receiver_email: user@email.com\r\n " \
        "jifiti_buyer_email: admin@maisonette.com\r\n jifiti_buyer_name: John Doe\r\n " \
        'jifiti_order_id: ABCD1234'
      end

      it { is_expected.to eq 'user@email.com' }
    end
  end
end

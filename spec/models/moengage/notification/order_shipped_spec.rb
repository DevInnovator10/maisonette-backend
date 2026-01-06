# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Moengage::Notification::OrderShipped do
  it { is_expected.to be_a(Moengage::Notification::Base) }

  describe '.title' do
    it 'returns the notification title text' do
      expect(described_class.new.title).to eq(I18n.t('moengage.notification.order_shipped.title'))
    end
  end

  describe '.subtitle' do
    it 'returns the notification subtitle text' do
      expect(described_class.new.subtitle).to eq(I18n.t('moengage.notification.order_shipped.subtitle'))
    end
  end

  describe '.message' do
    it 'returns the notification message text' do
      expect(described_class.new.message).to eq(I18n.t('moengage.notification.order_shipped.message'))
    end
  end
end

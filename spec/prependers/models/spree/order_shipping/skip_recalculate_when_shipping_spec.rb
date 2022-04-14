# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderShipping::SkipRecalculateWhenShipping, type: :model do
  let(:order) { create(:order_ready_to_ship) }

  context 'when the order is shipped' do
    it 'skip_recalculate option is set on the order_updater instance' do
      expect { order.shipments.each(&:ship!) }.to change { order.updater.skip_recalculate }.from(nil).to(true)
    end
  end
end

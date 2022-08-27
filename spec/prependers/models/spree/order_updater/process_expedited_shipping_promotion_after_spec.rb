# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderUpdater::ProcessExpeditedShippingPromotionAfter, type: :model do
  subject(:update_item_promotions) { described_class.new(order).send :update_item_promotions }

  let(:described_class) { Spree::OrderUpdater }
  let(:order) { instance_double Spree::Order, line_items: line_items, shipments: shipments }
  let(:line_items) { [line_item_1, line_item_2] }
  let(:line_item_1) { instance_double Spree::LineItem, adjustments: li_adjustments_1, :promo_total= => true }
  let(:line_item_2) { instance_double Spree::LineItem, adjustments: li_adjustments_2, :promo_total= => true }
  let(:li_adjustments_1) { [li_adjustment_1, li_adjustment_2] }
  let(:li_adjustments_2) { [li_adjustment_3, li_adjustment_4] }
  let(:li_adjustment_1) do
    instance_double Spree::Adjustment,
                    promotion?: true,
                    recalculate: true,
                    source: detract_other_shipping_cost_source,
                    eligible?: true,
                    amount: 5
  end
  let(:li_adjustment_2) { instance_double Spree::Adjustment, promotion?: false, recalculate: true }
  let(:li_adjustment_3) do
    instance_double Spree::Adjustment,
                    promotion?: true,
                    recalculate: true,
                    source: some_other_source,
                    eligible?: true,
                    amount: 5
  end
  let(:li_adjustment_4) { instance_double Spree::Adjustment, promotion?: false, recalculate: true }
  let(:shipments) { [shipment_1, shipment_2] }
  let(:shipment_1) { instance_double Spree::Shipment, adjustments: ship_adjustments_1, :promo_total= => true }
  let(:shipment_2) { instance_double Spree::Shipment, adjustments: ship_adjustments_2, :promo_total= => true }
  let(:ship_adjustments_1) { [ship_adjustment_1, ship_adjustment_2] }
  let(:ship_adjustments_2) { [ship_adjustment_3, ship_adjustment_4] }
  let(:ship_adjustment_1) do
    instance_double Spree::Adjustment,
                    promotion?: true,
                    recalculate: true,
                    source: detract_other_shipping_cost_source,
                    eligible?: true,
                    amount: 5
  end
  let(:ship_adjustment_2) { instance_double Spree::Adjustment, promotion?: false, recalculate: true }
  let(:ship_adjustment_3) do
    instance_double Spree::Adjustment,
                    promotion?: true,
                    recalculate: true,
                    source: some_other_source,
                    eligible?: true,
                    amount: 5
  end
  let(:ship_adjustment_4) { instance_double Spree::Adjustment, promotion?: false, recalculate: true }

  let(:detract_other_shipping_cost_source) { Spree::Promotion::Actions::DetractOtherShippingCost.new }
  let(:some_other_source) { Spree::Promotion::Actions::FreeShipping.new }
  let(:promotion_chooser) { instance_double Maisonette::PromotionChooser, update: true }

  before do
    allow(Maisonette::PromotionChooser).to receive(:new).and_return(promotion_chooser)

    update_item_promotions
  end

  it 'calculates the expedited shipments last' do
    expect(li_adjustment_1).to have_received(:recalculate).ordered
    expect(li_adjustment_3).to have_received(:recalculate).ordered
    expect(ship_adjustment_3).to have_received(:recalculate).ordered
    expect(ship_adjustment_1).to have_received(:recalculate).ordered
  end
end

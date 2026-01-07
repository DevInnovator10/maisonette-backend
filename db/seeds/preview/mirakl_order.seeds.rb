# frozen_string_literal: true

after 'preview:order' do
  spree_order = Spree::Order.complete.last
  return unless spree_order

  shipment = spree_order.shipments[0]
  line_item = shipment.line_items[0]
  commercial_order_id = spree_order.number
  mirakl_commercial_order = Mirakl::CommercialOrder.find_or_initialize_by(spree_order: spree_order,
                                                                          commercial_order_id: commercial_order_id)
  notify_if_saved(mirakl_commercial_order, mirakl_commercial_order.commercial_order_id)

  mirakl_order_line = Mirakl::OrderLine.find_or_initialize_by(mirakl_order_line_id: commercial_order_id + '-A-1',
                                                              line_item: line_item,
                                                              state: :REFUSED)

  mirakl_order = Mirakl::Order.find_or_initialize_by(
    commercial_order: mirakl_commercial_order,
    logistic_order_id: commercial_order_id + '-A',
    shipment: shipment,
    order_lines: [mirakl_order_line],
    state: :REFUSED,
    mirakl_payload: { 'order_additional_fields' => [],
                      'order_lines' => [{ 'quantity' => 1,
                                          'price' => 15.0,
                                          'shipping_price' => 0.2,
                                          'total_price' => 15.02,
                                          'order_line_id' => mirakl_order_line.mirakl_order_line_id,
                                          'order_line_state' => 'REFUSED' }] }
  )
  notify_if_saved(mirakl_order, mirakl_order.logistic_order_id)

  mirakl_order_line_reimbursement = Mirakl::OrderLineReimbursement.find_or_initialize_by(
    mirakl_reimbursement_id: commercial_order_id + '-A-1-1',
    mirakl_type: :rejection,
    order_line: mirakl_order_line,
    amount: 10.0,
    shipping_amount: 2.5,

    tax: 1.5,
    shipping_tax: 0.2,
    quantity: 1,
    refund_reason: Spree::RefundReason.last,
    inventory_units: [line_item.inventory_units[0]]
  )

  notify_if_saved(mirakl_order_line_reimbursement, mirakl_order_line_reimbursement.mirakl_reimbursement_id)
  mirakl_order_line_reimbursement.calculate_total
end

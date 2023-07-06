# frozen_string_literal: true

after 'preview:spree',
      'preview:user',
      'preview:product',
      'preview:stock_location',
      'preview:promotion_category' do
  Spree::User.joins(:addresses).limit(20).each do |user|
    order = Spree::Order.create!(
      user: user,
      bill_address: user.bill_address,
      ship_address: user.ship_address
    )
    product = Spree::Product.joins(:variants).sample

    variant = product.variants.first

    price = variant.currently_valid_prices.first

    line_item = order.contents.add(variant, 1, options: { vendor_id: price.vendor.id })

    order.recalculate

    notify(order, order.to_s)

    shipment = order.shipments.create!(
      stock_location: price.vendor.stock_location
    )
    shipment.shipping_rates.create!(shipping_method: Spree::ShippingMethod.find_by(name: 'Ground'), selected: true)
    shipment.inventory_units.create!(line_item: line_item, variant: line_item.variant)
    shipment.suppress_mailer = true
    order.update!(
      state: :complete,
      completed_at: Time.zone.now,
      payment_state: 'paid'
    )

    shipment.ready!
    shipment.ship!

    order.update!(payment_state: 'paid')
  end

  # Order with monograms
  Spree::User.joins(:addresses).sample.tap do |user|
    order = Spree::Order.create!(
      user: user,
      bill_address: user.bill_address,
      ship_address: user.ship_address
    )
    product = Spree::Product.joins(:variants).find_by(name: 'Monogrammable Rachel Cardigan, Navy')

    variant = product.variants.first

    price = variant.currently_valid_prices.first

    order.contents.add(
      variant,
      1,
      options: { vendor_id: price.vendor.id },
      monogram_attributes: {
        customization: {
          font: { name: 'Block', value: 'Plantin Web,Times New Roman,Times,"serif"' },
          color: { name: 'Snow White', value: '#ffffff' }
        },
        text: 'John Doe',
        price: 20
      }
    )
    order.recalculate

    notify(order, order.to_s)
  end

  # Cancelled order (for cancel email preview)
  Spree::User.joins(:addresses).sample.tap do |user|
    order = Spree::Order.create!(
      user: user,
      bill_address: user.bill_address,
      ship_address: user.ship_address
    )
    product = Spree::Product.joins(:variants).sample

    variant = product.variants.first

    price = variant.currently_valid_prices.first

    line_item = order.contents.add(variant, 1, options: { vendor_id: price.vendor.id })
    order.recalculate

    shipment = order.shipments.create!(
      stock_location: price.vendor.stock_location
    )
    shipment.shipping_rates.create!(shipping_method: Spree::ShippingMethod.find_by(name: 'Ground'), selected: true)
    shipment.inventory_units.create!(line_item: line_item, variant: line_item.variant)
    shipment.suppress_mailer = true

    order.update!(
      state: :complete,
      completed_at: Time.zone.now,
      payment_state: 'paid'
    )

    order.cancel!

    notify(order, order.to_s)
  end

  # Order with reimbursement (for reimbursement email preview)
  Spree::User.joins(:addresses).sample.tap do |user|
    order = Spree::Order.create!(
      user: user,
      bill_address: user.bill_address,
      ship_address: user.ship_address
    )
    product = Spree::Product.joins(:variants).sample

    variant = product.variants.first

    price = variant.currently_valid_prices.first

    line_item = order.contents.add(variant, 1, options: { vendor_id: price.vendor.id })
    order.recalculate

    stock_location = price.vendor.stock_location

    shipment = order.shipments.create!(
      stock_location: stock_location
    )
    shipment.shipping_rates.create!(shipping_method: Spree::ShippingMethod.find_by(name: 'Ground'), selected: true)
    inventory_unit = shipment.inventory_units.create!(line_item: line_item, variant: line_item.variant)
    shipment.suppress_mailer = true

    order.update!(
      state: :complete,
      completed_at: Time.zone.now,
      payment_state: 'paid'
    )

    shipment.ready!
    shipment.ship!

    order.update!(payment_state: 'paid')

    return_authorization = order.return_authorizations.create!(
      stock_location: stock_location,
      return_items_attributes: [
        {
          inventory_unit_id: inventory_unit.id,
          amount: line_item.amount,
          preferred_reimbursement_type_id: Spree::ReimbursementType.find_by(name: 'Store Credit').id,
          return_reason_id: Spree::ReturnReason.active.first.id,
          acceptance_status: :accepted,
          reception_status: :received
        }
      ]
    )

    return_item = return_authorization.return_items.first

    customer_return = Spree::CustomerReturn.create!(
      stock_location_id: stock_location.id,
      return_items: [return_item]
    )

    reimbursement = Spree::Reimbursement.build_from_customer_return customer_return
    reimbursement.save!

    notify(order, order.to_s)
  end

  # Order with cancelled inventory units (for inventory cancellation email preview)
  Spree::User.joins(:addresses).sample.tap do |user|
    order = Spree::Order.create!(
      user: user,
      bill_address: user.bill_address,
      ship_address: user.ship_address
    )
    product = Spree::Product.joins(:variants).sample

    variant = product.variants.first

    price = variant.currently_valid_prices.first

    line_item = order.contents.add(variant, 1, options: { vendor_id: price.vendor.id })
    order.recalculate

    shipment = order.shipments.create!(
      stock_location: price.vendor.stock_location
    )
    shipment.shipping_rates.create!(shipping_method: Spree::ShippingMethod.find_by(name: 'Ground'), selected: true)
    inventory_unit = shipment.inventory_units.create!(line_item: line_item, variant: line_item.variant)
    shipment.suppress_mailer = true

    order.update!(
      state: :complete,
      completed_at: Time.zone.now,
      payment_state: 'paid'
    )

    order.cancellations.short_ship [inventory_unit]

    notify(order, order.to_s)
  end

  # Order with gift card applied
  Spree::User.joins(:addresses).sample.tap do |user|
    order = Spree::Order.create!(
      user: user,
      bill_address: user.bill_address,
      ship_address: user.ship_address
    )
    product = Spree::Product.joins(:variants).sample

    variant = product.variants.first

    price = variant.currently_valid_prices.first

    order.contents.add(
      variant,
      1,
      options: { vendor_id: price.vendor.id }
    )
    order.recalculate

    gift_card = Maisonette::GiftCardGeneratorOrganizer.call!(
      original_amount: order.total - 1,
      name: 'Gift Card'
    ).gift_card

    order.coupon_code = gift_card.value

    Spree::PromotionHandler::Coupon.new(order).apply

    order.recalculate

    notify(order, order.to_s)
  end

  # Order with GiftcCard reimbursement (for reimbursement email preview)
  Spree::User.joins(:addresses).sample.tap do |user|
    order = Spree::Order.create!(
      user: user,
      bill_address: user.bill_address,
      ship_address: user.ship_address
    )
    product = Spree::Product.joins(:variants).sample

    variant = product.variants.first

    price = variant.currently_valid_prices.first

    line_item = order.contents.add(variant, 1, options: { vendor_id: price.vendor.id })
    total = line_item.total
    mirakl_order_line_id = 'CA1234567'
    order.recalculate

    stock_location = price.vendor.stock_location

    shipment = order.shipments.create!(
      stock_location: stock_location
    )
    shipment.shipping_rates.create!(shipping_method: Spree::ShippingMethod.find_by(name: 'Ground'), selected: true)
    inventory_unit = shipment.inventory_units.create!(line_item: line_item, variant: line_item.variant)
    shipment.suppress_mailer = true

    order.update!(
      state: :complete,
      completed_at: Time.zone.now,
      payment_state: 'paid'
    )

    shipment.ready!
    shipment.ship!

    order.update!(payment_state: 'paid')

    return_authorization = order.return_authorizations.create!(
      stock_location: stock_location,
      gift_recipient_email: order.email,
      return_items_attributes: [
        {
          inventory_unit_id: inventory_unit.id,
          amount: line_item.amount,
          preferred_reimbursement_type_id: Spree::ReimbursementType.find_by(name: 'GiftCard').id,
          return_reason_id: Spree::ReturnReason.active.first.id,
          acceptance_status: :accepted,
          reception_status: :received
        }
      ]
    )

    return_item = return_authorization.return_items.first

    customer_return = Spree::CustomerReturn.create!(
      stock_location_id: stock_location.id,

      return_items: [return_item]
    )

    reimbursement = Spree::Reimbursement.build_from_customer_return customer_return
    reimbursement.reimbursement_status = 'reimbursed'
    reimbursement.save!

    result = Maisonette::GiftCardGeneratorOrganizer.call!(
      original_amount: total,
      name: "Refund for Mirakl order line #{mirakl_order_line_id}"
    )

    Spree::Reimbursement::GiftCard.create!(
      spree_promotion_code_id: result.promotion_code.id,
      reimbursement: reimbursement,
      amount: total
    )

    notify(order, order.to_s)
  end
end

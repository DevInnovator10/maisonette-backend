# frozen_string_literal: true

module SolidusPaypalBraintree::Gateway::Base
  def customer_profile_params(payment)
    params = add_customer_info(super, payment)

    return params unless payment&.source&.credit_card? &&
                         (billing_address = payment&.order&.billing_address)

    params.merge!(
      credit_card: {
        billing_address: spree_address_to_braintree_address_attributes(billing_address)
      }
    )
  end

  private

  def add_customer_info(params, payment)
    shipping_address = payment.order.shipping_address

    params.merge(
      email: payment&.order&.email,
      first_name: shipping_address.first_name,
      last_name: shipping_address.last_name,
      phone: shipping_address.phone
    )
  end

  def spree_address_to_braintree_address_attributes(spree_address)
    {
      first_name: spree_address.firstname,
      last_name: spree_address.lastname,
      street_address: [spree_address.address1, spree_address.address2].compact.join(' '),
      locality: spree_address.city,
      postal_code: spree_address.zipcode,
      region: spree_address.state.to_s,
      country_code_alpha2: spree_address.country.iso
    }
  end

  def transaction_options(source, options, submit_for_settlement: false)
    params = super

    if params[:shipping].blank?
      params[:shipping] = braintree_shipping_address(options)
    end

    if params[:billing].blank?
      params[:billing] = braintree_billing_address(options)
    end

    params
  end
end

# frozen_string_literal: true

module Admin
  module Orders
    module Edit
      class CustomerDetailsPage < SitePrism::Page
        element :use_billing, '#order_use_billing'
        set_url '/admin/orders/{number}/customer/edit'

        def fill_in_billing_address(address)
          fill_in 'order_bill_address_attributes_firstname', with: address.first_name
          fill_in 'order_bill_address_attributes_lastname', with: address.last_name
          fill_in 'order_bill_address_attributes_address1', with: address.address1
          fill_in 'order_bill_address_attributes_address2', with: address.address2
          fill_in 'order_bill_address_attributes_city', with: address.city
          fill_in 'order_bill_address_attributes_zipcode', with: address.zipcode
          select address.state.name, from: 'order_bill_address_attributes_state_id'
          fill_in 'order_bill_address_attributes_phone', with: address.phone
        end
      end
    end
  end
end

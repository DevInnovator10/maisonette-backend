# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::SalesOrderPresenter do
  describe '#payload' do
    let(:api_version) { '54.0' }
    let(:address) do
      create(
        :address,
        address1: '123 1st Street',
        city: 'New York',
        state_code: 'NY',
        country_iso_code: 'US',
        zipcode: '12345',
        first_name: 'John',
        last_name: 'Doe',
        phone: '+1 (222) 111-3333'
      )
    end
    let(:user) do
      create(
        :user,
        first_name: 'John',
        last_name: 'Doe',
        email: 'john@example.com',
        bill_address: address
      )
    end
    let(:credit_card_payment) { create(:credit_card_payment, :solidus_paypal_braintree_credit_card, amount: 10) }
    let(:gift_card_adjustment) { create(:adjustment, source: gift_card) }
    let(:gift_card) { create(:spree_gift_card, original_amount: 10) }
    let(:store_credit_payment) { build(:store_credit_payment, amount: 80) }
    let(:store_credit_payment_2) { build(:store_credit_payment, amount: 5.8) }
    let(:store_credit_payment_3) { build(:store_credit_payment, amount: 4.2) }
    let(:invalid_payment) { build(:store_credit_payment, state: :invalid) }
    let(:vendor) { create(:vendor, name: 'Vendor Name', avalara_code: 'avalara_code') }
    let(:mirakl_offer) { create(:mirakl_offer, price: price.amount, offer_id: 123) }
    let(:sales_order) { create(:sales_order) }
    let(:order_item) { create(:order_item_summary) }
    let(:order_item_shipment) { create(:order_item_summary) }
    let(:price_book_entry) do
      build_stubbed(:order_management_price_book_entry, order_management_entity_ref: 'PRICEREF')
    end
    let(:order) do
      create(
        :completed_order_with_totals,
        number: 'ORD12345',
        user: user,
        billing_address: address,
        shipping_address: address,
        sales_order: sales_order,
        channel: 'order_channel',
        is_gift: false,
        line_items_attributes: [{ variant: variant, price: price.amount, vendor: vendor, mirakl_offer: mirakl_offer }],
        shipment_cost: 19.95,
        payments: valid_payment_collection + invalid_payment_collection,
        adjustments: [gift_card_adjustment]
      )
    end
    let(:valid_payment_collection) do
      [
        credit_card_payment,
        store_credit_payment,
        store_credit_payment_2,
        store_credit_payment_3
      ]
    end
    let(:invalid_payment_collection) { [invalid_payment] }

    let(:variant) { create(:variant, prices: [price]) }
    let(:price) { create(:price, vendor: vendor, amount: 100) }

    before do
      allow(OrderManagement::OrderItemSummary).to receive(:find_by!).with(
        summarable_type: 'Spree::LineItem',
        summarable_id: order.line_items.last.id,
        sales_order_id: sales_order.id
      ).and_return(order_item)
      allow(OrderManagement::OrderItemSummary).to receive(:find_by!).with(
        summarable_type: 'Spree::Shipment',
        summarable_id: order.shipments.last.id,
        sales_order_id: sales_order.id
      ).and_return(order_item_shipment)
      allow(OrderManagement::PriceBookEntry).to receive(:find_by!).and_return(price_book_entry)

      variant = order.line_items.first.variant
      variant.assign_attributes(weight: 5, depth: 4, height: 3, cost_price: 50)
      variant.offer_settings.build(maisonette_sku: variant.sku, vendor_id: order.line_items.first.vendor_id)
      variant.product.update(name: 'Product name')
      variant.save!

      shipment = order.shipments.first
      shipment.shipping_method.update(
        base_flat_rate_amount: 9.95,
        expedited: true,
        expedited_flat_rate_adjustment: 10,
        mirakl_shipping_method_code: 'second-day-air'
      )

      OrderManagement::OrderDeliveryMethod.find_by(order_manageable: shipment.shipping_method)
                                          .update(order_management_entity_ref: 'REFODM123')

      OrderManagement::Product.find_by(order_manageable: order.line_items.reload.first.offer_settings)
                              .update(order_management_entity_ref: 'ENTREF1')
      create(:vendor, name: 'Maisonette', avalara_code: '2001')

      allow(Mirakl::PostSubmitOrder::CalculateLeadTimeToShipInteractor).to receive(:call).and_return(
        double( # rubocop:disable RSpec/VerifiedDoubles
          Interactor::Context, success?: true, ship_by: Time.zone.local(2021, 5, 31, 10, 10, 10)
        )
      )
      allow(order.payments).to receive(:valid).and_return(valid_payment_collection)
      allow(credit_card_payment.source).to receive_messages(
        last_4: '2701', card_type: 'Visa', expiration_year: '2021', expiration_month: '5'
      )
    end

    it 'includes the account subrequest' do
      external_id = OrderManagement::Account.find_by(order_manageable: order.maisonette_customer).external_id

      expected_payload = {
        method: 'PATCH',
        url: "/services/data/v54.0/sobjects/Account/External_Id__c/#{external_id}",
        referenceId: 'refAcc',
        body: {
          FirstName: 'John',
          LastName: 'Doe',
          PersonEmail: 'john@example.com',
          UUID__c: order.maisonette_customer_id
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    it 'includes the order subrequest' do # rubocop:disable RSpec/ExampleLength
      expected_payload = {
        method: 'POST',
        url: '/services/data/v54.0/sobjects/Order',
        referenceId: 'refOrder',
        body: {
          Order_Number__c: 'ORD12345',
          Pricebook2Id: '01s4W000000oj5uQAA',
          Status: 'Draft',
          EffectiveDate: order.completed_at.iso8601,
          BillingStreet: '123 1st Street',
          BillingCity: 'New York',
          BillingState: 'New York',
          BillingPostalCode: '12345',
          BillingCountry: 'US',
          Channel__c: 'order_channel',
          Is_Gift__c: false,
          Gift_Email__c: nil,
          Gift_Message__c: nil,
          Guest_Checkout__c: order.guest_checkout?,
          AccountId: '@{refAcc.id}',
          OrderReferenceNumber: 'ORD12345',
          Commercial_ID__c: 'ORD12345',
          Environment__c: 'test',
          SalesChannelId: '0bI1b0000008OaOEAU',
          OrderedDate: order.created_at.iso8601
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    it 'includes the payment group subrequest' do
      expected_payload = {
        method: 'POST',
        url: '/services/data/v54.0/sobjects/PaymentGroup',
        referenceId: 'refPaymentGroup',
        'body': {
          'SourceObjectId': '@{refOrder.id}'
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    it 'includes the payment sources subrequest' do # rubocop:disable RSpec/ExampleLength
      expected_payload = {
        method: 'POST',
        url: '/services/data/v54.0/composite/sobjects',
        referenceId: 'refPaymentSources',
        body: {
          allOrNone: true,
          records: [
            {
              attributes: {
                type: 'CardPaymentMethod'
              },
              AccountId: '@{refAcc.id}',
              CardCategory: 'CreditCard',
              CardLastFour: '2701',
              CardType: 'Visa',
              ExpiryMonth: '5',
              ExpiryYear: '2021',
              PaymentGatewayId: '0b01b0000000001AAA',
              ProcessingMode: 'External',
              Status: 'Active'
            },
            {
              attributes: {
                type: 'DigitalWallet'
              },
              Type: 'Store Credit',
              AccountId: '@{refAcc.id}',
              Status: 'Active',
              ProcessingMode: 'External',
              GatewayToken: '2020',
              PaymentGatewayId: '0b01b0000004C9DAAU'
            },
            {
              attributes: {
                type: 'DigitalWallet'
              },
              Type: 'Gift Card',
              AccountId: '@{refAcc.id}',
              Status: 'Active',
              ProcessingMode: 'External',
              GatewayToken: '2020',
              PaymentGatewayId: '0b01b0000004C9DAAU'
            }
          ]
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    it 'includes flat rate delivery group subrequest' do
      expected_payload = {
        method: 'POST',
        url: '/services/data/v54.0/sobjects/OrderDeliveryGroup',
        referenceId: 'refFlatRateDeliveryGroup',
        body: {
          EmailAddress: 'john@example.com',
          DeliverToCity: 'New York',
          DeliverToCountry: 'US',
          DeliverToName: 'John Doe',
          DeliverToPostalCode: '12345',
          DeliverToState: 'NY',
          DeliverToStreet: '123 1st Street',
          PhoneNumber: '+1 (222) 111-3333',
          OrderDeliveryMethodId: 'REFODM123',
          OrderId: '@{refOrder.id}'
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    context 'when the flat rate delivery group payload returns empty' do
      it 'does not includes an empty flat rate delivery group subrequest' do
        order.shipments.first.shipping_method.update!(expedited: false, base_flat_rate_amount: 0)
        expected_payload = {
          method: 'POST',
          url: '/services/data/v54.0/composite/sobjects',
          referenceId: 'refFlatRateDeliveryGroup',
          body: {
            allOrNone: true,
            records: [nil]
          }
        }

        composite_request = described_class.new(order, api_version).payload[:compositeRequest]

        expect(composite_request).not_to match array_including(expected_payload)
        expect(composite_request).not_to match array_including(nil)
      end
    end

    it 'includes delivery groups subrequest' do # rubocop:disable RSpec/ExampleLength
      expected_payload = {
        method: 'POST',
        url: '/services/data/v54.0/composite/sobjects',
        referenceId: 'refDeliveryGroups',
        body: {
          allOrNone: true,
          records: [
            {
              attributes: {
                type: 'OrderDeliveryGroup'
              },
              EmailAddress: 'john@example.com',
              DeliverToCity: 'New York',
              DeliverToCountry: 'US',
              DeliverToName: 'John Doe',
              DeliverToPostalCode: '12345',
              DeliverToState: 'NY',
              DeliverToStreet: '123 1st Street',
              PhoneNumber: '+1 (222) 111-3333',
              OrderDeliveryMethodId: 'REFODM123',
              OrderId: '@{refOrder.id}',
              Parent_Delivery_Group_ID__c: '@{refFlatRateDeliveryGroup.id}'
            }
          ]
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    context 'when the delivery groups payload returns empty' do
      it 'does not includes an empty delivery groups subrequest' do
        order.shipments.first.shipping_method.update!(expedited: false, expedited_flat_rate_adjustment: 0)
        expected_payload = {
          method: 'POST',
          url: '/services/data/v54.0/composite/sobjects',
          referenceId: 'refDeliveryGroups',
          body: {
            allOrNone: true,
            records: []
          }
        }

        composite_request = described_class.new(order, api_version).payload[:compositeRequest]

        expect(composite_request).not_to match array_including(expected_payload)
        expect(composite_request).not_to match array_including(nil)
      end
    end

    it 'includes the order details subrequest' do # rubocop:disable RSpec/ExampleLength
      expected_payload = {
        method: 'POST',
        url: '/services/data/v54.0/composite/sobjects',
        referenceId: 'refOrderDetails',
        body: {
          allOrNone: true,
          records: [
            {
              attributes: { type: 'Payment' },
              AccountId: '@{refAcc.id}',
              Amount: 10.0,
              GatewayRefNumber: credit_card_payment.response_code,
              PaymentGatewayId: '0b01b0000000001AAA',
              PaymentGroupId: '@{refPaymentGroup.id}',
              PaymentMethodId: '@{refPaymentSources[0].id}',
              Payment_Number__c: credit_card_payment.number,
              ProcessingMode: 'External',
              Status: 'Processed',
              Type: 'Capture'
            },
            {
              attributes: {
                type: 'Payment'
              },
              Amount: 4.2,
              ProcessingMode: 'External',
              Status: 'Processed',
              PaymentGroupId: '@{refPaymentGroup.id}',
              AccountId: '@{refAcc.id}',
              PaymentMethodId: '@{refPaymentSources[1].id}',
              PaymentGatewayId: '0b01b0000000001AAA',
              GatewayRefNumber: store_credit_payment_3.response_code,
              Payment_Number__c: store_credit_payment_3.number,
              Type: 'Capture',
              Store_Credit_Info__c: "#{store_credit_payment.number}:80.0,#{store_credit_payment_2.number}:5.8"
            },
            {
              attributes: {
                type: 'Payment'
              },
              Amount: 10.0,
              ProcessingMode: 'External',
              Status: 'Processed',
              PaymentGroupId: '@{refPaymentGroup.id}',
              AccountId: '@{refAcc.id}',
              PaymentMethodId: '@{refPaymentSources[2].id}',
              PaymentGatewayId: '0b01b0000000001AAA',
              GatewayRefNumber: gift_card_adjustment.source.promotion_code.value,
              Payment_Number__c: gift_card_adjustment.source.promotion_code.value,
              Type: 'Capture'
            },
            {
              attributes: {
                type: 'OrderAdjustmentGroup'
              },
              Name: 'Promotion: 20% off Order Amount Over $100',
              Description: 'Promotion: 20% off Order Amount Over $100',
              Type: 'Header',
              OrderId: '@{refOrder.id}'
            }
          ]
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    it 'includes the line items subrequest' do # rubocop:disable RSpec/ExampleLength
      expected_payload = {
        method: 'POST',
        url: '/services/data/v54.0/composite/sobjects',
        referenceId: 'refLineItemsGroup',
        body: {
          allOrNone: true,
          records: [
            {
              attributes: {
                type: 'OrderItem'
              },
              Type: 'Order Product',
              Quantity: 1,
              TotalLineAmount: 100.0,
              UnitPrice: 100.0,
              Vendor__c: 'Vendor Name',
              Product2Id: 'ENTREF1',
              PricebookEntryId: 'PRICEREF',
              OrderDeliveryGroupId: '@{refDeliveryGroups[0].id}',
              OrderId: '@{refOrder.id}',
              Shipping_Price__c: 19.95,
              Shipping_Type__c: 'second-day-air',
              Offer_price__c: 100.0,
              Offer_ID__c: 123,
              mirakl_offer_price__c: 100.0,
              mirakl_offer_id__c: 123,
              Monogram_Data__c: nil,
              Shipping_Deadline__c: '2021-05-31T10:10:10-04:00',
              total_cost_price__c: 50.0,
              External_ID__c: order_item.external_id,
              avalara_merchant_seller_identifier__c: 'avalara_code',
              Description: 'Product name - Size: S'
            },
            {
              attributes: {
                type: 'OrderItem'
              },
              Description: 'Shipping',
              Type: 'Delivery Charge',
              Quantity: 1,
              TotalLineAmount: 19.95,
              UnitPrice: 19.95,
              Product2Id: '01t1b000002KSJNAA4',
              PricebookEntryId: '01u1b000005oYUgAAM',
              OrderDeliveryGroupId: '@{refDeliveryGroups[0].id}',
              OrderId: '@{refOrder.id}',
              Shipping__c: true,
              External_ID__c: order_item_shipment.external_id,
              avalara_merchant_seller_identifier__c: '2001'
            }
          ]
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end

    context 'when the adjustments subrequest is generated' do
      it 'includes all the line item adjustments' do # rubocop:disable RSpec/ExampleLength
        line_item = order.line_items.first
        shipment = order.shipments.first
        item_promo_category = create(:promotion_category, code: 'line_item_adjustment', name: 'line_item_adjustment')
        item_promo = create(:promotion, :with_line_item_adjustment, promotion_category: item_promo_category)

        create(:adjustment, adjustable: line_item, eligible: true, source: item_promo.actions.first, label: 'Promotion')
        create(:adjustment, label: 'Shipping Adjustment', amount: -5.00, adjustable: shipment)

        expected_payload = {
          method: 'POST',
          url: '/services/data/v54.0/composite/sobjects',
          referenceId: 'refAdjustments',
          body: {
            allOrNone: true,
            records: [
              {
                attributes: {
                  type: 'OrderItemAdjustmentLineItem'
                },
                Name: 'Promotion',
                Amount: 100.0,
                OrderItemId: '@{refLineItemsGroup[0].id}',
                OrderAdjustmentGroupId: '@{refOrderDetails[3].id}'
              },
              {
                attributes: {
                  type: 'OrderItemAdjustmentLineItem'
                },
                Name: 'Shipping Adjustment',
                Amount: -5.00,
                OrderItemId: '@{refLineItemsGroup[1].id}',
                OrderAdjustmentGroupId: '@{refOrderDetails[3].id}'
              }
            ]
          }
        }

        expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
          array_including(expected_payload)
        )
      end

      it 'includes the tax adjustment' do # rubocop:disable RSpec/ExampleLength
        line_item = order.line_items.first
        create(:tax_adjustment, label: 'Avalara Tax', amount: 10.0, adjustable: line_item)

        expected_payload = {
          method: 'POST',
          url: '/services/data/v54.0/composite/sobjects',
          referenceId: 'refAdjustments',
          body: {
            allOrNone: true,
            records: [
              {
                attributes: {
                  type: 'OrderItemTaxLineItem'
                },
                Name: 'Avalara Tax',
                Type: 'Estimated',
                Amount: 10.0,
                TaxEffectiveDate: line_item.adjustments.first.created_at.iso8601,
                OrderItemId: '@{refLineItemsGroup[0].id}'
              }
            ]
          }
        }

        expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
          array_including(expected_payload)
        )
      end
    end

    it 'includes the update order subrequest' do
      expected_payload = {
        method: 'PATCH',
        url: '/services/data/v54.0/sobjects/Order/@{refOrder.id}',
        referenceId: 'refUpdateOrder',
        body: {
          Status: 'Activated'
        }
      }

      expect(described_class.new(order, api_version).payload[:compositeRequest]).to match(
        array_including(expected_payload)
      )
    end
  end
end

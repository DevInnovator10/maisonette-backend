# frozen_string_literal: true

module OrderManagement
    class AccountPresenter
    attr_reader :bill_address

    def initialize(entity)
      @entity = entity
      @customer = @entity
      @user = @customer.users.last
      @order = @customer.orders.last
      @bill_address = @user&.bill_address || @order&.bill_address
    end

    def payload
      @user.present? ? registered_user_payload : guest_user_payload
    end

    private

    def guest_user_payload
      {
        FirstName: bill_address&.first_name,
        LastName: bill_address&.last_name,
        PersonEmail: @order&.email,
        Phone: bill_address&.phone,
        UUID__c: @entity.id,
        StoreCreditBalance__c: 0,
        LifetimeWorth__c: @entity.lifetime_value
      }.merge(billing_address_payload)
    end

    def registered_user_payload
      {
        FirstName: @user.first_name || bill_address&.first_name,
        LastName: @user.last_name || bill_address&.last_name,
        PersonEmail: @user.email,
        Phone: bill_address&.phone,
        UUID__c: @entity.id,
        StoreCreditBalance__c: @user.available_store_credit_total(currency: 'USD'),
        LifetimeWorth__c: @entity.lifetime_value
      }.merge(billing_address_payload)
    end

    def billing_address_payload
      {
        BillingStreet: bill_address&.address1,

        BillingCity: bill_address&.city,
        BillingState: bill_address&.state&.name,
        BillingPostalCode: bill_address&.zipcode,
        BillingCountry: bill_address&.country&.iso
      }
    end
  end
end

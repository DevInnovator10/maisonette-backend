# frozen_string_literal: true

module Mirakl
  class PostSubmitOrderOrganizer < ApplicationOrganizer
    organize Mirakl::Easypost::CreateOrderOrganizer,
             Mirakl::PostSubmitOrder::BuildShipByDatePayloadInteractor,
             Mirakl::BuildMarkDownCreditPayloadInteractor,
             Mirakl::BuildCostPriceFeePayloadInteractor,
             Mirakl::BuildGiftDetailsPayloadInteractor,
             Mirakl::BuildOrderFeePayloadInteractor,
             Mirakl::PostSubmitOrder::BuildDefaultWarehousePayloadInteractor,
             Mirakl::SubmitOrderAdditionalFieldsInteractor
  end
end

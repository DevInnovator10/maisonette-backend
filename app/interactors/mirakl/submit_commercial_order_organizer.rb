# frozen_string_literal: true

module Mirakl
  class SubmitCommercialOrderOrganizer < ApplicationOrganizer
    organize SubmitCommercialOrder::CreateOfferDetailsPayloadInteractor,
             SubmitCommercialOrder::CreateCommercialOrderPayloadInteractor,
             SubmitCommercialOrder::PostCommercialOrderToMirakl
  end
end

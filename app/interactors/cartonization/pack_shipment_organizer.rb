# frozen_string_literal: true

module Cartonization
  class PackShipmentOrganizer < ApplicationOrganizer
    organize Cartonization::PrepareCartonizationInteractor,
             Cartonization::ShipsAloneInteractor,
             Cartonization::MailerInteractor,
             Cartonization::PaccurateInteractor
  end
end

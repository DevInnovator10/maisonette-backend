# frozen_string_literal: true

module Narvar
  class CreateOrderWithShipmentsOrganizer < ApplicationOrganizer
    organize Narvar::CreateOrderInteractor, Narvar::UpdateShipmentsInteractor
  end
end

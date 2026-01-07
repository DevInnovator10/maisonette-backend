# frozen_string_literal: true

module Narvar
  class UpdateOrderWithShipmentsOrganizer < ApplicationOrganizer
    organize Narvar::UpdateOrderInteractor, Narvar::UpdateShipmentsInteractor
  end
end

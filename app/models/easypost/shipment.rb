# frozen_string_literal: true

module Easypost
  class Shipment < Easypost::Base
    belongs_to :easypost_order, class_name: 'Easypost::Order', optional: false
    belongs_to :easypost_parcel, class_name: 'Easypost::Parcel', optional: false
  end
end

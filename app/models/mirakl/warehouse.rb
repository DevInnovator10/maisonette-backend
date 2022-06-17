# frozen_string_literal: true

module Mirakl
  class Warehouse < Mirakl::Base
    belongs_to :mirakl_shop, class_name: 'Mirakl::Shop', optional: false
    belongs_to :address, class_name: 'Spree::Address', optional: false

    validates :name, presence: true
  end
end

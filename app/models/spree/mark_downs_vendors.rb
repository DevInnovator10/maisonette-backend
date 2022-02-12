# frozen_string_literal: true

module Spree
  class MarkDownsVendors < ApplicationRecord
    belongs_to :vendor, optional: false
    belongs_to :mark_down, optional: false
  end
end

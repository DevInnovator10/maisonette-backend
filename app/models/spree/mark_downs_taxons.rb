# frozen_string_literal: true

module Spree
    class MarkDownsTaxons < ApplicationRecord
    belongs_to :taxon, optional: false
    belongs_to :mark_down, optional: false
  end

end

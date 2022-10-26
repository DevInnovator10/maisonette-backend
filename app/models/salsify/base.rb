# frozen_string_literal: true

module Salsify
  class Base < ApplicationRecord
    self.table_name_prefix = 'salsify_'
    self.abstract_class = true
  end
end

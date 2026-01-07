# frozen_string_literal: true

module Mirakl
  class Base < ApplicationRecord
    self.table_name_prefix = 'mirakl_'
    self.abstract_class = true
  end
end

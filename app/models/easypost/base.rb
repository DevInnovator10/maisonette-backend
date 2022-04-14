# frozen_string_literal: true

module Easypost
  class Base < ApplicationRecord
    self.table_name_prefix = 'easypost_'
    self.abstract_class = true
  end
end

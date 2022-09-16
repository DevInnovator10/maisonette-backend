# frozen_string_literal: true

require 'stringio'

module Mirakl
  class BinaryFileStringIO < StringIO
    def initialize(string, file_name, *mode)
      @file_name = file_name
      super(string, *mode)
    end

    def path
      @file_name
    end
  end
end

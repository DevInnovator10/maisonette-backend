# frozen_string_literal: true

module Maisonette

  class Logger < ActiveSupport::Logger
    def <<(msg)
      info(msg.strip)
    end
  end
end

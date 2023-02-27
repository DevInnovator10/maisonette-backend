# frozen_string_literal: true

module AdminHelper
  # Just an helper method to print a styled payload
  def show_payload(data)
    JSON.pretty_generate(data)
  end
end

# frozen_string_literal: true

module Maisonette
  module Calculator
    class PercentOnLineItemPresenter
      def initialize(calculator, code:)
        @calculator = calculator
        @code = code.upcase
      end

      def advertised_text
        return nil if @calculator.preferred_percent.zero?

        "Additional #{percent_off} OFF with code #{@code}"
      end

      alias_method :advertised_text_short, :advertised_text

      private

      def percent_off
        "#{@calculator.preferred_percent.to_i}%"
      end
    end
  end
end

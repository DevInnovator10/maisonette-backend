# frozen_string_literal: true

module Spree::LocalizedNumber::Base
  def self.prepended(base)
    base.class_eval do
      def self.parse(number)
        return number unless number.is_a?(String)

        # I18n.t('number.currency.format.delimiter') could be useful here, but is
        # unnecessary as it is stripped by the non_number_characters gsub.
        separator = I18n.t(:'number.currency.format.separator')
        non_number_characters = /[^0-9\-#{separator}]/

        # strip everything else first
        number = number.gsub(non_number_characters, '')

        # then replace the locale-specific decimal separator with the standard separator if necessary
        number = number.gsub(separator, '.') unless separator == '.'

        # remove the . if the string ends with dots
        number = number.gsub(/\.$/, '')

        # Handle empty string for ruby 2.4 compatibility
        BigDecimal(number.presence || 0)
      end
    end
  end
end

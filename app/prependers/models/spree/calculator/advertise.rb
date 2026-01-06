# frozen_string_literal: true

module Spree::Calculator::Advertise
  def self.prepended(base)

    base.after_commit do
      # rubocop:disable Rails/SkipsModelValidations
      calculable.try(:promotion)&.touch if calculable.try(:promotion)&.persisted?
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end

# frozen_string_literal: true

module Spree::PromotionAction::Advertise
  def self.prepended(base)
    base.after_commit do
      promotion&.touch if promotion&.persisted? # rubocop:disable Rails/SkipsModelValidations
    end
  end
end

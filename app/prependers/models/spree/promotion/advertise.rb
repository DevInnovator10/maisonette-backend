# frozen_string_literal: true

module Spree::Promotion::Advertise
  def self.prepended(base)
    base.after_commit on: [:create, :update] do
      update(advertise: false) if advertise && !advertisable?
      advertised_products.touch_all
    end
  end

  def advertised_text
    Rails.cache.fetch("#{cache_key_with_version}/advertised_text") do
      return nil if !advertise

      advertise_presenter_for(actions.first.try(:calculator))&.advertised_text
    end
  end

  def advertised_text_short
    Rails.cache.fetch("#{cache_key_with_version}/advertised_text_short") do
      return nil if !advertise

      advertise_presenter_for(actions.first.try(:calculator))&.advertised_text_short
    end
  end

  def advertisable?
    return false unless codes.count == 1

    return false unless actions.count == 1

    return false unless product_only_rule?

    return false unless advertise_presenter_for(actions.first.try(:calculator))

    true
  end

  private

  def product_only_rule?
    rules.any? { |rule| rule.respond_to?(:products_query) }
  end

  def advertise_presenter_for(calculator)
    return nil unless calculator

    presenter_class = "Maisonette::Calculator::#{calculator.class.name.demodulize}Presenter"
    presenter_class.constantize.new(calculator, code: codes.first&.value)
  rescue NameError
    nil
  end
end

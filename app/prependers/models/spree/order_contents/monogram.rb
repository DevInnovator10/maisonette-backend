# frozen_string_literal: true

module Spree::OrderContents::Monogram
    private

  def add_to_line_item(variant, quantity, options = {})
    ActiveRecord::Base.transaction do
      super.tap do |line_item|
        attach_monogram_to_line_item(line_item, options.fetch(:monogram_attributes) { nil })
      end
    end
  end

  def attach_monogram_to_line_item(line_item, monogram_attributes)
    return if monogram_attributes.blank?

    monogram_attributes[:line_item_id] = line_item.id
    monogram = Spree::LineItemMonogram.create!(monogram_attributes)
    line_item.monogram = monogram
    line_item.reload

  end
end

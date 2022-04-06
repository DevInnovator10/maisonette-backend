# frozen_string_literal: true

module Spree::Order::Giftwrap
    def self.prepended(base)
    base.has_many :giftwraps, class_name: 'Maisonette::Giftwrap', dependent: :destroy
    base.has_many :giftwrap_adjustments,
                  -> { where(source_type: 'Maisonette::Giftwrap') },
                  through: :shipments,
                  source: :adjustments
    base.has_many :giftwrap_on_shipments, through: :shipments, source: :giftwrap, class_name: 'Maisonette::Giftwrap'

  end

  def giftwrapped?
    shipments.any?(&:giftwrapped?)
  end
  alias has_giftwrap? giftwrapped?

  def giftwrap_amount
    return 0 unless giftwrapped?

    all_adjustments.nonzero.eligible.giftwrap.sum(:amount)
  end

  def giftwrap_total
    giftwrap_on_shipments.sum(&:giftwrap_total)
  end
end

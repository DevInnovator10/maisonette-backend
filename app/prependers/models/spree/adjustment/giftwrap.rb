# frozen_string_literal: true

module Spree::Adjustment::Giftwrap
  def self.prepended(base)
    base.scope :giftwrap, -> { where(source_type: 'Maisonette::Giftwrap') }
  end

  def giftwrap?
    source_type == 'Maisonette::Giftwrap'
  end
end

# frozen_string_literal: true

# Adds `non_shipping` scope to promotion_discount
# Changes manual discounts to use custom scope
module SolidusAvataxCertified::Request::GetTax::FixDiscount
  def generate
    {
      createTransactionModel: {
        code: order.number,
        date: doc_date,
        discount: total_discount.to_s,
        commit: @commit,
        type: doc_type,
        lines: sales_lines
      }.merge(base_tax_hash)
    }
  end

  private

  def promotion_discount
    order.all_adjustments
         .promotion
         .non_shipping # TODO: remove non_shipping when adding shipping tax
         .eligible
         .sum(:amount)
         .abs
  end

  def manual_discount
    order.all_adjustments
         .where('amount < 0')
         .manual
         .eligible
         .sum(:amount)
         .abs
  end

  def total_discount
    promotion_discount + manual_discount
  end

  def doc_type
    @doc_type || 'SalesOrder'
  end
end

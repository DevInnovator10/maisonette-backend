# frozen_string_literal: true

module Spree::Api::ReturnAuthorizationsController::Mine
    def self.prepended(base)

    base.include MineConcerns
    base.before_action :load_order, except: [:mine, :my_return]
  end

  def my_return
    return unauthorized unless current_api_user

    @order = return_authorization.order
    @refunded_total = return_authorization.customer_returns.joins(:reimbursements).sum(:total)
  end

  def mine
    @return_authorizations = begin
      current_api_user.return_authorizations
                      .joins('LEFT OUTER JOIN spree_return_items ON
                              spree_return_items.return_authorization_id = spree_return_authorizations.id')
                      .group('spree_return_authorizations.id', 'spree_orders.number')
                      .select(
                        'spree_return_authorizations.*',
                        'sum(spree_return_items.amount + spree_return_items.additional_tax_total) as return_amount',
                        'spree_orders.number as order_number'
                      )
                      .order(created_at: :desc)
    end
  end

  private

  def return_authorization
    @return_authorization ||= return_authorization_scope.find_by!(number: params[:number])
  end

  def return_authorization_scope
    current_api_user.admin? ? Spree::ReturnAuthorization : current_api_user.return_authorizations
  end
end

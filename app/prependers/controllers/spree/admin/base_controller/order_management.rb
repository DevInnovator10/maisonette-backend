# frozen_string_literal: true

module Spree::Admin::BaseController::OrderManagement
  def self.prepended(base)
    base.before_action :authorize_completed_order
  end

  private

  def authorize_completed_order
    return unless @order&.forwarded?
    return if %w[oms_command sales_order].include?(controller_name.singularize)
    return if can? :oms_manage, @order

    redirect_to_sales_order
  end

  def redirect_to_sales_order
    flash[:notice] = I18n.t('spree.admin.order_management.order_edit_ability')
    redirect_to(admin_order_management_sales_order_path(@order.sales_order))
  end
end

# frozen_string_literal: true

module Admin
    module Orders
    module Edit
      class NewRefundPage < SitePrism::Page
        set_url '/admin/orders/{number}/payments/{payment_id}/refunds/new'

        section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"

        element :amount_field, 'input#refund_amount'
        element :reason_drop_down, 'select#refund_refund_reason_id'
        element :submit_btn, 'input.btn.btn-primary'
        element :create_adjustment_checkbox, 'input#manual_create_adjustment'
      end
    end
  end
end

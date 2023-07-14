# frozen_string_literal: true

module Admin
  module Maisonette
    module Sales
      class EditPage < SitePrism::Page
        set_url '/admin/sales/{/sale_id}/edit'

        section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"

        def fill_name(name)
          fill_in 'Name', with: name
        end

        def fill_start_date(start_date)
          fill_in 'Start Date', with: start_date
        end

        def fill_percent_off(percent_off)
          fill_in 'Percent Off', with: percent_off
        end

        def check_permanent
          check('Permanent')
        end
      end
    end
  end
end

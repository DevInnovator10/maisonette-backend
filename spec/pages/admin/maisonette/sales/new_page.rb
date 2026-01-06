# frozen_string_literal: true

module Admin
  module Maisonette
    module Sales
      class NewPage < SitePrism::Page
        set_url '/admin/sales/new'

        section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"

        def fill_in_form(name)
          fill_in 'Name', with: name
          fill_in 'Percent Off', with: '10'
          fill_in 'Maisonette Liability', with: '10'
          fill_in 'Start Date', with: '2050-03-01'
          fill_in 'End Date', with: '2051-03-01'
        end
      end
    end
  end
end

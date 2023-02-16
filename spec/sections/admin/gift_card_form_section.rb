# frozen_string_literal: true

require_relative './form_buttons_actions_section.rb'

module Admin
  class GiftCardFormSection < SitePrism::Section
    element :name_field, "input[id='gift_card_name']"

    section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"
  end
end

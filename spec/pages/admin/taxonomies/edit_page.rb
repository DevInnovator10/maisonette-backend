# frozen_string_literal: true

module Admin
  module Taxonomy
    class EditPage < SitePrism::Page
      set_url '/admin/taxonomies{/taxonomy_id}/edit'

      element :publish_nav_button, '#clear_nav_cache'
    end
  end
end

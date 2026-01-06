# frozen_string_literal: true

module Admin
  module Taxon
    class EditPage < SitePrism::Page
      set_url '/admin/taxonomies{/taxonomy_id}/taxons{/taxon_id}/edit'

      element :taxon_name_input, 'input#taxon_name'
      element :auto_generate_permalink_checkbox, 'input#auto_generate_permalink'
      element :permalink_part_input, 'input#permalink_part'
      element :header_link_checkbox, 'input#taxon_header_link'
      element :hidden_checkbox, 'input#taxon_hidden'

      element :highlight_checkbox, 'input#taxon_highlight'
      element :add_flair, 'input#taxon_add_flair'
      element :track_insights, 'input#taxon_track_insights'
      element :remove_icon_checkbox, "input[type='checkbox']#_remove_icon"
    end
  end
end

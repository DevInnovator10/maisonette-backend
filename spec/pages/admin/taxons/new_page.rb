# frozen_string_literal: true

module Admin
  module Taxon
    class NewPage < SitePrism::Page
      set_url '/admin/taxonomies{/taxonomy_id}/taxons/new{?parent_id}'

      element :name_field, '#taxon_name'
      element :permalink_field, '#permalink_part'
      element :auto_generate_permalink, '#auto_generate_permalink'
    end
  end
end

# frozen_string_literal: true

module Feature
  module Select2FeatureHelper
    def select2(name, options)
      find(options[:css]).tap do |tag|
        tag.click
        tag.fill_in with: name
      end
      find(:xpath, '//body').tap do |body|
        body.find('.select2-result-label', text: name).click
        body.find('.select2-search-choice', text: name) # wait for a choice to appear in the select
      end
    end
  end
end

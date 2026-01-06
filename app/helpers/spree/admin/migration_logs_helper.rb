# frozen_string_literal: true

module Spree
  module Admin
    module MigrationLogsHelper
      def pill_status(log) # rubocop:disable Metrics/MethodLength
        pill_name = case log.status
                    when 'completed', 'fixed'
                      'complete'
                    when 'failed_but_saved', 'require_verification', 'bad_data'
                      'warning'
                    when 'created'
                      'pending'
                    else
                      'error'
                    end

        content_tag(:span, class: "pill pill-#{pill_name}") do
          log.status
        end
      end
    end
  end
end

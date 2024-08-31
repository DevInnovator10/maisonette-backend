# frozen_string_literal: true

module Solidus
  module Deprecation
    extend self

    def override_warn_when_gte(rails_version: nil, solidus_version: nil)
      return notify_useless_code(:solidus, solidus_version) if solidus_version_matches?(solidus_version)
      return notify_useless_code(:rails, rails_version) if rails_version_matches?(rails_version)
    end

    def override_warn_if
      return unless yield

      message = 'Please review this deprecated code, it may be included in the bundled version of Solidus'
      ActiveSupport::Deprecation.warn(message, caller_method)
    end

    private

    def notify_useless_code(gem, version)
      ActiveSupport::Deprecation.warn(
        "You can now use #{gem.capitalize} (#{version}) version of this method.",
        caller_method
      )
    end

    def rails_version_matches?(version)
      return false if version.blank?

      Rails.gem_version >= Gem::Version.new(version)
    end

    def solidus_version_matches?(version)
      return false if version.blank?

      Spree.solidus_gem_version >= Gem::Version.new(version)
    end

    def caller_method
      caller_stack_depth = 2
      Rails.gem_version < Gem::Version.new('5.0') ? caller(caller_stack_depth) : caller_locations(caller_stack_depth)
    end
  end
end

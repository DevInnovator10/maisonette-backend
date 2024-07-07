# frozen_string_literal: true

module Maisonette
  module Flipper
    module Identifier
      def flipper_id
        to_gid.to_s
      end
    end

  end
end

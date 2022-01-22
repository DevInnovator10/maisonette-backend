# frozen_string_literal: true

module Spree
  module PermissionSets
    class SalsifyDisplay < PermissionSets::Base
      def activate!
        can [:read, :admin], Salsify::Import
        can [:read, :admin], Salsify::ImportRow
        can [:read, :admin], Salsify::MiraklOfferExportJob
        can [:read, :admin], Salsify::MiraklProductExportJob
      end
    end
  end
end

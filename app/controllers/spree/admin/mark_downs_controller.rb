# frozen_string_literal: true

module Spree
  module Admin
    class MarkDownsController < ResourceController
      def collection
        return @collection if @collection

        @active_search = params[:q]&.values&.any?(&:present?)
        prepare_ransack_params
        @search = super.ransack(params[:q])
        filter_search_collection
      end

      def export_collection
        Spree::ExportMarkDownsJob.perform_later(mark_down_ids: params[:mark_down_ids], user: current_spree_user)
        flash[:success] = "CSV will be emailed to #{current_spree_user.email}"
        redirect_back fallback_location: admin_mark_downs_path
      end

      def edit
        @prices = @mark_down.prices
                            .includes(:vendor, variant: :product)
                            .order('spree_vendors.name', 'spree_products.name')
                            .page(params[:page])
                            .per(params[:per_page] || 25)
      end

      def destroy
        Spree::MarkDownDestroyWorker.perform_async(@object.id)
        flash[:success] = 'Deleting in background.. Please wait for email response.'
        respond_with(@object) do |format|
          format.html { redirect_to location_after_destroy }
          format.js { render partial: 'spree/admin/shared/destroy' }
        end
      end

      private

      def permitted_resource_params
        super.tap do |super_params|
          super_params[:mark_downs_taxons] = taxons_param.compact
          super_params[:mark_downs_vendors] = vendors_param.compact
        end
      end

      def include_taxon_ids
        @include_taxon_ids ||= params[:mark_down].delete(:include_taxon_ids).split(',')
      end

      def exclude_taxon_ids
        @exclude_taxon_ids ||= params[:mark_down].delete(:exclude_taxon_ids).split(',')
      end

      def include_vendor_ids
        @include_vendor_ids ||= params[:mark_down].delete(:include_vendor_ids).split(',')
      end

      def exclude_vendor_ids
        @exclude_vendor_ids ||= params[:mark_down].delete(:exclude_vendor_ids).split(',')
      end

      def taxons_param
        include_taxon_ids.map { |id| @mark_down.included_mark_downs_taxons.find_or_initialize_by(taxon_id: id) } +
          exclude_taxon_ids.map { |id| @mark_down.excluded_mark_downs_taxons.find_or_initialize_by(taxon_id: id) }
      end

      def vendors_param
        include_vendor_ids.map { |id| @mark_down.included_mark_downs_vendors.find_or_initialize_by(vendor_id: id) } +
          exclude_vendor_ids.map { |id| @mark_down.excluded_mark_downs_vendors.find_or_initialize_by(vendor_id: id) }
      end

      def prepare_ransack_params
        params[:q] ||= {}
        params[:q]['mark_downs_taxons_taxon_id_in'] = params[:q]['mark_downs_taxons_taxon_id_in']&.split(',')
        params[:q]['mark_downs_vendors_vendor_id_in'] = params[:q]['mark_downs_vendors_vendor_id_in']&.split(',')
      end

      def filter_search_collection
        collection = @search.result.distinct
        active_on = params[:q][:active_on]
        collection = collection.active_on(active_on) if active_on&.to_date.is_a? Date
        @collection = collection.order(created_at: :desc)
                                .page(params[:page])
                                .per(Spree::Config[:admin_products_per_page])
      end

      def flash_message_for(object, event_sym)
        super + ' You will receive an email when prices have been updated.'
      end
    end
  end
end

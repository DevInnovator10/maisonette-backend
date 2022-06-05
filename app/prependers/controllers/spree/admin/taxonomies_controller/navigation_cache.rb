# frozen_string_literal: true

module Spree::Admin::TaxonomiesController::NavigationCache
    def clear_nav_cache
    Rails.cache.delete(Spree::Taxonomy.navigation_cache_key(params[:taxonomy_name]))
    Rails.logger.info I18n.t('spree.admin.taxonomies.clear_nav_cache_log', email: current_spree_user.email)

    head :no_content
  end
end

# frozen_string_literal: true

I18n.t('seeds.taxonomies').each do |taxonomy_data|
  taxonomy = Spree::Taxonomy.find_or_initialize_by(name: taxonomy_data[:name])
  notify_if_saved(taxonomy, taxonomy_data[:name])

  taxonomy.root.update(permalink: taxonomy_data[:permalink]) if taxonomy_data[:permalink]

  if taxonomy.persisted?
    instance_variable_set("@taxonomy_#{taxonomy.name.downcase}", taxonomy)
    instance_variable_set("@taxon_#{taxonomy.name.downcase}", taxonomy.root)
  end
end

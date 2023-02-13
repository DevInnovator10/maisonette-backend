# frozen_string_literal: true

module Easypost
    class Order < Easypost::Base
    module CustomsForm
      def send_customs_form
        customs_form = master_easypost_shipment.forms.detect do |form|
          form.form_type == EASYPOST_DATA[:forms][:customs]
        end
        return unless customs_form

        Mirakl::SubmitOrderDocInteractor.call(mirakl_order: spree_shipment.mirakl_order,
                                              binary_file: customs_form_binary_file(customs_form),
                                              doc_type: MIRAKL_DATA[:order][:documents][:customs_form])
      end

      private

      def customs_info
        return if spree_shipment.order.ship_address.country.iso == spree_shipment.stock_location.country.iso

        ::EasyPost::CustomsInfo.create(eel_pfc: EASYPOST_DATA[:customs][:eel_pfc],
                                       customs_certify: EASYPOST_DATA[:customs][:customs_certify],
                                       contents_type: EASYPOST_DATA[:customs][:contents_type],
                                       contents_explanation: contents_explanation,
                                       customs_items: customs_items)
      end

      def contents_explanation
        main_category_taxon = Spree::Taxon.find_by(name: Spree::Taxonomy::MAIN_CATEGORY)
        product_type_taxon = Spree::Taxon.find_by(name: Spree::Taxonomy::PRODUCT_TYPE)
        category_combinations = spree_shipment.line_items.map do |line_item|
          main_category_name = line_item.product.taxons.find_by(parent: main_category_taxon)&.name
          product_type_name = line_item.product.taxons.find_by(parent: product_type_taxon)&.name

          "#{main_category_name}/#{product_type_name}"
        end.uniq.join(', ')
        "Sale of #{category_combinations}"[0...255]
      end

      def customs_items
        spree_shipment.line_items.map do |line_item|
          variant = line_item.variant
          quantity = line_item.quantity
          total_price = line_item.total
          total_weight = (variant.property('Box1 Packaged Weight').to_f * quantity)
          total_weight_in_oz = Measured::Weight(total_weight, :lbs).convert_to(:oz).value.to_f
          country_iso = customs_country_iso(variant.property('Country of Origin')&.strip)

          create_customs_item(country_iso, quantity, total_price, total_weight_in_oz, variant)
        end
      end

      def create_customs_item(country_iso, quantity, total_price, total_weight, variant)
        ::EasyPost::CustomsItem.create(description: variant.name,
                                       quantity: quantity,
                                       value: total_price.to_f,
                                       weight: total_weight,
                                       hs_tariff_number: variant.property('Tariff Codes'),
                                       origin_country: country_iso)
      end

      def customs_country_iso(country_name)
        (Spree::Country.find_by(name: country_name) ||
          Spree::Country.find_by(iso_name: country_name) ||
          Spree::Country.find_by(iso: country_name) ||
          Spree::Country.find_by(iso3: country_name))&.iso
      end

      def customs_form_binary_file(customs_form)
        customs_form_string = RestClient.get(customs_form.form_url).body
        Mirakl::BinaryFileStringIO.new(customs_form_string, "customs_form_#{customs_form.id}.pdf")
      end
    end
  end
end

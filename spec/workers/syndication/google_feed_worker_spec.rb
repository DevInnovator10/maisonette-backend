# frozen_string_literal: false

require 'rails_helper'

RSpec.describe Syndication::GoogleFeedWorker do
    let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform }

    let(:file_path) { Rails.root.join('tmp', described_class::FILENAME).to_s }
    let(:file) { instance_double File }
    let(:file_contents) do
      '<channel>
        <title>Maisonette</title>
        <link>http://localhost:7777</link>
        <item><g:id>#{variant.maisonette_sku}</g:id>
        <g:gtin>#{product.upc}</g:gtin>
        <g:mpn>#{variant.maisonette_sku}</g:mpn>
        <g:title>#{product.product_name}</g:title>
        <g:description>#{product.vendor_sku_description}</g:description>
        <g:link>#{product.product_url}</g:link></item>
      </channel>'
    end
    let(:remote_path) { "metric-theory/#{described_class::FILENAME}" }
    let(:maisonette_syndication_bucket) { 'maisonette-syndication-tst' }
    let(:s3_region) { 'us-east-1' }

    before do
      allow(worker).to receive_messages(generate_xml: true)
      allow(File).to receive(:open).and_yield(file)
      allow(File).to receive(:read).with(file_path).and_return(file_contents)
      allow(S3).to receive(:put)

      perform
    end

    it 'calls generate_xml with file' do
      expect(File).to have_received(:open).with(file_path, 'w')
      expect(worker).to have_received(:generate_xml).with(file)
    end

    it 'calls S3.put with the file contents as public-read' do
      expect(S3).to have_received(:put).with(remote_path,
                                             file_contents,
                                             acl: 'public-read',
                                             bucket: maisonette_syndication_bucket,
                                             region: s3_region)
    end

    context 'when file not generated' do
      let(:file_contents) do
        '<channel>
          <title>Maisonette</title>
          <link>http://localhost:7777</link>
        </channel>'
      end

      it 'not calls S3.put with the file contents as public-read when file is empty' do
        expect(S3).not_to have_received(:put).with(remote_path,
                                                   file_contents,
                                                   acl: 'public-read',
                                                   bucket: maisonette_syndication_bucket,
                                                   region: s3_region)
      end
    end
  end

  describe '#generate_xml' do
    subject(:generate_xml) { worker.send(:generate_xml, file) }

    # rubocop:disable RSpec/VerifiedDoubles
    let(:xml_builder) { double Builder::XmlMarkup, instruct!: true }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:file) { instance_double File }
    let(:variants) { class_double Spree::Variant }
    let(:variant1) { instance_double Spree::Variant }
    let(:variant2) { instance_double Spree::Variant }

    before do
      allow(Builder::XmlMarkup).to receive(:new).and_return(xml_builder)
      allow(xml_builder).to receive(:rss).and_yield
      allow(xml_builder).to receive(:channel).and_yield
      allow(worker).to receive_messages(build_meta: true,
                                        variants_query: variants,
                                        build_feed_item: true)
      allow(variants).to receive(:find_each).and_yield(variant1).and_yield(variant2)

      generate_xml
    end

    it 'builds XmlMarkup with the given file' do
      expect(Builder::XmlMarkup).to have_received(:new).with(target: file)
    end

    it 'calls instruct!, rss and channel on the xml builder' do
      expect(xml_builder).to have_received(:instruct!)
      expect(xml_builder).to have_received(:rss).with(version: '2.0', "xmlns:g": 'http://base.google.com/ns/1.0')
      expect(xml_builder).to have_received(:channel)
    end

    it 'calls build_meta with the xml builder' do
      expect(worker).to have_received(:build_meta).with(xml_builder)
    end

    it 'calls build_feed_item with each variant and the xml_builder' do
      expect(worker).to have_received(:build_feed_item).with(xml_builder, variant1)
      expect(worker).to have_received(:build_feed_item).with(xml_builder, variant2)
    end
  end

  describe '#build_meta' do
    subject(:build_meta) { worker.send(:build_meta, xml_builder) }

    # rubocop:disable RSpec/VerifiedDoubles
    let(:xml_builder) { double Builder::XmlMarkup }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:default_spree_store) { instance_double Spree::Store, name: 'Maisonette' }
    let(:base_url) { 'www.maisonette.com' }

    before do
      allow(xml_builder).to receive_messages(title: true, link: true)
      allow(Spree::Store).to receive_messages(default: default_spree_store)
      allow(Maisonette::Config).to receive(:fetch).with('base_url').and_return(base_url)

      build_meta
    end

    it 'calls title on xml builder' do
      expect(xml_builder).to have_received(:title).with(default_spree_store.name)
    end

    it 'calls link on xml builder' do
      expect(xml_builder).to have_received(:link).with(base_url)
    end
  end

  describe '#variants_query' do
    subject(:variants_query) { worker.send(:variants_query) }

    let(:purchasable_variants) { class_double Spree::Variant, joins: joins_product_purchasable_variants }
    let(:joins_product_purchasable_variants) do
      class_double Spree::Variant, includes: includes_product_purchasable_variants
    end
    let(:includes_product_purchasable_variants) { class_double Spree::Variant }

    it 'returns purchasable variants' do
      skip 'unable to mock :purchasable'
      expect(variants_query).to eq includes_product_purchasable_variants

      expect(purchasable_variants).to have_received(:joins).with(:product)
      expect(joins_product_purchasable_variants).to have_received(:includes).with(:product)
    end
  end

  describe '#build_feed_item' do
    subject(:build_feed_item) { worker.send(:build_feed_item, xml_builder, variant) }

    let(:variant) { create :syndication_product, :for_variant }
    let(:product) { create :syndication_product, :for_product, maisonette_sku: variant.manufacturer_id }
    let(:xml_builder) { Builder::XmlMarkup.new }

    let(:xml) do
      "<item>
<g:id>#{variant.maisonette_sku}</g:id>
<g:gtin>#{product.upc}</g:gtin>
<g:mpn>#{variant.maisonette_sku}</g:mpn>
<g:title>#{product.product_name}</g:title>
<g:description>#{product.vendor_sku_description}</g:description>
<g:link>#{product.product_url}</g:link>
<g:image_link>#{product.image}</g:image_link>
<g:side_image_link>#{product.side_image}</g:side_image_link>
<g:condition>New</g:condition>
<g:gender>unisex</g:gender>
<g:google_product_category>#{product.google_product_category}</g:google_product_category>
<g:brand>#{product.brand}</g:brand>
<g:item_group_id>#{product.maisonette_sku}</g:item_group_id>
<g:age_group>toddler</g:age_group>
<g:color>#{product.color.join(';')}</g:color>
<g:material>#{product.material}</g:material>
<g:availability>in stock</g:availability>
<g:price>#{variant.maisonette_retail}</g:price>
<g:sale_price>#{variant.maisonette_sale}</g:sale_price>
<g:size>#{variant.size}</g:size>
<g:shipping_category>#{variant.shipping_category}</g:shipping_category>
<g:margin>#{product.margin}</g:margin>
<g:shipping>#{variant.estimated_shipping_cost.to_f}</g:shipping>
<g:product_type>#{product.product_type.join(';')}</g:product_type>
<g:size_broken>#{product.size_broken}</g:size_broken>
<g:cost_price>#{variant.cost_price}</g:cost_price>
<g:exclusive_definition>#{product.exclusive_definition}</g:exclusive_definition>
</item>
<to_s/>".gsub("\n", '') # The to_s is there because of the test, it's not normally there.
    end

    context 'when it is successful' do
      before do
        product

        build_feed_item
      end

      it 'creates an xml with variant/product details' do
        expect(xml_builder.to_s).to eq xml
      end

      context 'when the product does not have an age range' do
        let(:product) do
          create :syndication_product, :for_product, maisonette_sku: variant.manufacturer_id, age_range: ''
        end

        it 'sends empty string as the age range' do
          expect(xml_builder.to_s).to include '<g:age_group></g:age_group>'
        end
      end

      context 'when the product is in a genderless category' do
        context 'when the product is unisex' do
          let(:product) do
            create :syndication_product,
                   :for_product,
                   maisonette_sku: variant.manufacturer_id,
                   category: %w[Gear Kids],
                   gender: ['Unisex']
          end

          it 'sends empty string as as the gender' do
            expect(xml_builder.to_s).to include '<g:gender></g:gender>'
          end
        end

        context 'when the product is not unisex' do
          let(:product) do
            create :syndication_product,
                   :for_product,
                   maisonette_sku: variant.manufacturer_id,
                   category: %w[Gear Kids],
                   gender: ['Girl']
          end

          it 'sends the gender' do
            expect(xml_builder.to_s).to include '<g:gender>female</g:gender>'
          end
        end
      end
    end

    context 'when an ActiveRecord::RecordNotFound exception is thrown ' do
      before do
        allow(Sentry).to receive(:capture_exception_with_message)

        build_feed_item
      end

      it 'capture ActiveRecord::RecordNotFound exception with Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(
          an_instance_of(ActiveRecord::RecordNotFound),
          message: 'Unable to find syndication product while building XML feed',
          extra: {
            syndication_product_id: variant.id,
            product_name: variant.manufacturer_id,
            marketplace_sku: variant.marketplace_sku
          }
        )
      end

      it 'returns nil' do
        expect(build_feed_item).to eq nil
      end
    end

    context 'when StandardError exception is thrown' do
      subject(:build_feed_item) { worker.send(:build_feed_item, xml_builder, variant_1) }

      let(:variant_1) { Spree::Variant.new }
      let(:product) { create :syndication_product, :for_product, maisonette_sku: variant_1.manufacturer_id }

      before do
        allow(Sentry).to receive(:capture_exception_with_message)

        build_feed_item
      end

      it 'capture StandardError exception with Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(an_instance_of(NoMethodError),
                                                                              message: variant_1.attributes.to_s)
      end

      it 'returns nil' do
        expect(build_feed_item).to eq nil
      end
    end
  end
end

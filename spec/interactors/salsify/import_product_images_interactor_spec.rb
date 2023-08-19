# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ImportProductImagesInteractor do
  describe '#call' do
    subject(:interactor_call) { described_class.call(options) }

    let(:options) {}

    it { is_expected.to be_a_failure }
    it { expect(interactor_call.messages).to match Salsify.salsify_error(:row_missing, prefix: '') }

    context 'with an import row' do
      let(:images) { 'https://www.someurl.com/an_image.jpg' }
      let(:import_row) do
        build(:salsify_import_row, :from_dev_file, spree_product: product).tap do |row|
          data = row.data.tap { |rd| rd['Image'] = images }
          row.data = data
        end
      end
      let(:options) { { import_row: import_row, variant_group_attributes: variant_group_attributes } }
      let(:variant_group_attributes) { nil }
      let(:product) {}

      it { is_expected.to be_a_failure }
      it { expect(interactor_call.messages).to match Salsify.salsify_error(:invalid_state, prefix: '') }

      context 'with an import row in imported state' do
        let(:import_row) { build :salsify_import_row, :from_dev_file, state: :imported }

        it { is_expected.to be_a_failure }
        it { expect(interactor_call.messages).to match Salsify.salsify_error(:product_missing, prefix: '') }
      end

      context 'with an import row in imported state with a product' do
        let(:product) do
          create(:product).tap do |prod|
            prod.master.images << current_image
            prod.master.images << old_image
          end
        end
        let(:current_image_url) { 'https://www.someurl.com/current_image_url.jpg' }
        let(:current_image) { create(:image, attachment_file_name: 'current_image.jpg', source_url: current_image_url) }
        let(:old_image) { create(:image, attachment_file_name: 'an_old_image.jpg', source_url: 'an_url/old_image.jpg') }
        let(:new_image_url) { 'https://www.someurl.com/an_image.jpg' }
        let(:images) { "#{new_image_url};#{current_image_url}" }

        before do
          import_row.imported!
          stub_request(:get, new_image_url).to_return(
            body: Rails.root.join('spec', 'fixtures', 'images', 'smiling-cat.jpg'),
            status: 200
          )
          stub_request(:get, current_image_url).to_return(
            body: Rails.root.join('spec', 'fixtures', 'images', 'thinking-cat.jpg'),
            status: 200
          )
        end

        it 'orders the product images as they are in the images url list' do
          expect(interactor_call).to be_a_success
          product.reload

          expect(product.images.first.source_url).to eq new_image_url
          expect(product.images.second.source_url).to eq current_image_url
          expect(product.images).not_to include old_image
        end

        context 'when variant_group_attributes context is present' do
          let(:variant_group_attributes) { create(:maisonette_variant_group_attributes) }
          let(:old_image) do
            create(
              :image,
              attachment_file_name: 'an_old_image.jpg',
              source_url: 'an_url/old_image.jpg',
              maisonette_variant_group_attributes_id: variant_group_attributes.id
            )
          end

          it 'assigns the variant_group_attributes id to the images' do
            expect(interactor_call).to be_a_success
            product.reload

            expect(product.images.first.source_url).to eq new_image_url
            expect(product.images.second.source_url).to eq current_image_url
            expect(product.images).not_to include old_image
            expect(
              product.images.pluck(:maisonette_variant_group_attributes_id).uniq
            ).not_to eq [variant_group_attributes.id]
          end
        end

        context 'when images are only reordered' do
          let(:old_image_url) { 'an_url/old_image.jpg' }
          let(:images) { "#{old_image_url};#{current_image_url}" }

          it 'reorders image position' do
            expect { interactor_call }.to change { old_image.reload.position }
              .from(2).to(1).and change { current_image.reload.position }.from(1).to(2)
          end
        end

        context 'with an invalid image url' do
          let(:images) { 'some://invalid.url' }

          it { is_expected.to be_a_failure }
          it { expect(interactor_call.messages).to match 'Invalid URL' }
        end

        context 'with a not available image (404)' do
          let(:error_message) { 'File not found' }

          before { allow(product.images).to receive(:build).and_raise(OpenURI::HTTPError.new(error_message, nil)) }

          it { is_expected.to be_a_failure }
          it { expect(interactor_call.messages).to start_with error_message }
        end

        context 'with an exception' do
          let(:error_message) { 'There was an error processing the thumbnail' }

          before { allow(product.images).to receive(:build).and_raise(StandardError.new(error_message)) }

          it { is_expected.to be_a_failure }
          it { expect(interactor_call.messages).to start_with error_message }
        end

        context 'with a duplicated image' do
          let(:images) { "#{new_image_url};#{current_image_url};#{new_image_url}" }

          before do
            interactor_call
            product.reload
          end

          it 'import unique images only' do
            images = product.images.map(&:source_url)
            expect(images.size).to eq images.uniq.size
          end
        end
      end

      context 'with a video asset' do
        let(:images) do
          'https://images.salsify.com/video/upload/s--GRq1nzv0--/e_trim/c_mpad,ar_1:1/if_w_lt_301,bo_15px_solid_white/if_w_lt_501_and_w_gt_300,c_pad,h_300,w_300,bo_24px_solid_white/if_w_lt_701_and_w_gt_500,c_pad,h_500,w_500,bo_40px_solid_white/if_w_lt_901_and_w_gt_700,c_pad,h_700,w_700,bo_56px_solid_white/if_w_lt_1101_and_w_gt_900,c_pad,h_900,w_900,bo_72px_solid_white/if_w_lt_1301_and_w_gt_1100,c_pad,h_1100,w_1100,bo_88px_solid_white/if_w_lt_1601_and_w_gt_1300,c_pad,h_1300,w_1300,bo_104px_solid_white/if_w_lt_1901_and_w_gt_1600,c_pad,h_1600,w_1600,bo_128px_solid_white/if_w_gt_1900,c_pad,h_1920,w_1920,bo_154px_solid_white/eo0ndlaoz5zuqufm9teu.mp4'
        end
        let(:valid_video_url) { 'https://images.salsify.com/video/upload/s--GRq1nzv0--/eo0ndlaoz5zuqufm9teu.mp4' }
        let(:product) { create(:product) }

        before do
          import_row.imported!
          stub_request(:get, %r{/video/upload/}).to_return(body: file_fixture('videos/sample.mp4'), status: 200)
        end

        it 'imports a video asset' do
          expect { interactor_call }.to change { product.reload.videos.count }.from(0).to(1)
          expect(interactor_call).to be_a_success
          expect(product.videos.last.attachment_file_name).to eq File.basename(valid_video_url)
          expect(product.videos.last.attachment_content_type).to eq 'video/mp4'
          expect(product.videos.last.source_url).to eq valid_video_url
        end
      end
    end
  end
end

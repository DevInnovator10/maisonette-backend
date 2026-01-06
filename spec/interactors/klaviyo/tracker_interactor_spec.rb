# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Klaviyo::TrackerInteractor do
  describe '#call' do
    let(:interactor) { described_class.new(args) }
    let(:context) { interactor.call }

    let(:args) { { gid: gid, event: event } }
    let(:event) { :complete }

    let(:order) { create :order_with_line_items }
    let(:order_gid) { order.to_gid.to_s }
    let(:line_item) { order.line_items.first }
    let(:line_item_gid) { line_item.to_gid.to_s }

    let(:client) { instance_double Klaviyo::Client, track: true, get_request: nil }

    let(:brand_taxon) { create :taxon, :brand_maison_you }

    before do
      allow(Klaviyo::Client).to receive(:new).and_return client
      allow(interactor).to receive(:public_send).and_call_original
    end

    context 'when validating the context' do
      let(:context) { described_class.call args }

      context 'when validating the record' do
        context 'when providing a valid gid' do
          before { line_item.product.taxons << brand_taxon }

          context 'when the record is an order' do
            let(:args) { { gid: order_gid, event: 'fulfilled' } }

            it { expect(context).to be_a_success }
          end

          context 'when the record is a line item' do
            let(:args) { { gid: line_item_gid, event: 'ordered_product' } }

            it { expect(context).to be_a_success }
          end
        end

        context 'when the record is not a line item or an order' do
          let(:args) { { gid: 'bad' } }

          it 'throws a klaviyo error' do
            expect(context).to be_a_failure
            expect(context.message).to eq I18n.t(:invalid_record, gid: 'bad', scope: 'errors.klaviyo.tracker')
          end
        end
      end

      context 'when validating the event' do
        context 'when providing an invalid event' do
          let(:args) { { gid: order_gid, event: 'foo' } }

          it 'throws a klaviyo error' do
            expect(context).to be_a_failure
            expect(context.message).to eq I18n.t(:invalid_event, event: 'foo', scope: 'errors.klaviyo.tracker')
          end
        end
      end

      context 'when validating the event for the provided record' do
        context 'when the record is an order' do
          context 'when the event is not ordered product' do
            let(:args) { { gid: order_gid, event: 'fulfilled' } }

            before { line_item.product.taxons << brand_taxon }

            it { expect(context).to be_a_success }
          end

          context 'when the event is ordered_product' do
            let(:args) { { gid: order_gid, event: 'ordered_product' } }

            it 'throws an error message' do
              expect(context).to be_a_failure
              message = I18n.t(
                :unable_to_process, event: 'ordered_product', gid: order_gid, scope: 'errors.klaviyo.tracker'
              )
              expect(context.message).to eq message
            end
          end
        end

        context 'when the record is a line item' do
          context 'when the event is ordered_product' do
            let(:args) { { gid: line_item_gid, event: 'ordered_product' } }

            before { line_item.product.taxons << brand_taxon }

            it { expect(context).to be_a_success }
          end

          context 'when the event is not ordered_product' do
            let(:args) { { gid: line_item_gid, event: 'complete' } }

            it 'throws a klaviyo error' do
              expect(context).to be_a_failure
              message = I18n.t(
                :unable_to_process, event: 'complete', gid: line_item_gid, scope: 'errors.klaviyo.tracker'
              )
              expect(context.message).to eq message
            end
          end
        end
      end
    end

    context 'when sending a completed order' do
      context 'when the record is an order' do
        let(:args) { { gid: order_gid, event: 'complete' } }

        before do
          line_item.product.taxons << brand_taxon
          context
        end

        it 'calls for the correct payload' do
          expect(client).to have_received(:track)
          expect(interactor).to have_received(:public_send).with('complete_payload')
        end
      end
    end

    context 'when sending a fulfilled order' do
      context 'when the record is an order' do
        let(:args) { { gid: order_gid, event: 'fulfilled' } }

        before do
          line_item.product.taxons << brand_taxon
          context
        end

        it 'calls for the correct payload' do
          expect(client).to have_received(:track)
          expect(interactor).to have_received(:public_send).with('fulfilled_payload')
        end
      end
    end

    context 'when sending an ordered product' do
      context 'when the record is an order' do
        let(:args) { { gid: line_item_gid, event: 'ordered_product' } }

        before do
          line_item.product.taxons << brand_taxon
          context
        end

        it 'calls for the correct payload' do
          expect(client).to have_received(:track)
          expect(interactor).to have_received(:public_send).with('ordered_product_payload')
        end
      end
    end
  end
end

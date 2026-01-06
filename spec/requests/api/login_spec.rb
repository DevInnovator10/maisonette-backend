# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  describe '#login' do
    let(:user) { create(:user, :with_api_key, password: 'valid123') }
    let(:password) { 'valid123' }
    let(:custom_headers) { { Accept: 'application/json' } }

    let(:do_request) { post '/api/users/login', headers: custom_headers, params: params }
    let(:params) { { user: { email: user.email, password: password } } }

    context 'when using a custom forwarded header' do
      let(:custom_header_ip) { FFaker::Internet.ip_v4_address }
      let(:custom_headers) { super().merge('X-Forwarded-For' => custom_header_ip) }

      before { do_request }

      it 'sets the header from the custom IP' do
        expect(response).to have_http_status :ok
        expect(Spree::User.find(json_response['id']).last_sign_in_ip).to eq custom_header_ip
      end
    end

    context 'when valid credentials' do
      before { do_request }

      it 'returns the user' do
        expect(status).to eq 200
        expect(json_response['id']).to eq user.id
        expect(headers['Authorization']).to be_present
        expect(headers['Authorization']).to match(/^Bearer .+$/)
      end
    end

    context 'when not valid credentials' do
      let(:password) { 'NOT VALID' }

      before { do_request }

      it 'returns the user' do
        expect(status).to eq 401
      end
    end

    context 'when logged out user has a cart' do
      let(:logged_out_order) { create :order_with_line_items, line_items_count: 1, user: nil }
      let(:custom_headers) { super().reverse_merge('X-Spree-Order-Token': logged_out_order.guest_token.to_s) }
      let(:params) { super().merge(order_number: logged_out_order.number) }

      context 'when logged in user does not have a cart' do
        it 'assigns the order to the logged in user' do
          expect(logged_out_order.user).to be_nil
          do_request
          expect(logged_out_order.reload.user).to eq user
        end

        context 'when the logging out user cart is in state :complete but no :completed_at' do
          let(:logged_out_order) { create :order_with_line_items, line_items_count: 1, user: nil }
          let(:current_order) { Spree::Order.where(user_id: user.id).last }

          before { logged_out_order.update_column(:state, :complete) }

          it 'assigns a new order to the user' do
            do_request
            expect(current_order).not_to eq logged_out_order
            expect(current_order.state).to eq 'cart'
          end
        end
      end

      context 'when logged in user does have a cart' do
        let(:existing_order) { create :order_with_line_items, line_items_count: 2, user: user }
        let(:existing_order_variants) { existing_order.line_items.map(&:variant) }

        before { logged_out_order && existing_order }

        it 'merges the existing user order INTO the current_order' do
          expect { do_request }.to change(logged_out_order.line_items, :count).from(1).to(3)
        end

        it 'deletes the existing order' do
          do_request
          expect(Spree::Order.find_by(id: existing_order)).to be_nil
        end

        it 'merges the variants with vendor_id correctly' do
          existing_line_item_variant_vendors = existing_order.line_items.pluck(:variant_id, :vendor_id)
          logged_out_line_item_variant_vendors = logged_out_order.line_items.pluck(:variant_id, :vendor_id)

          do_request

          new_variant_vendors = logged_out_order.reload.line_items.pluck(:variant_id, :vendor_id)
          expect(new_variant_vendors).to match_array existing_line_item_variant_vendors +
                                                     logged_out_line_item_variant_vendors
        end

        context 'when the logging in user cart is in the checkout flow' do
          let(:logged_out_order) { create :order_ready_to_complete, email: 'foo@bar.com', user: nil }
          let(:existing_order) { create :order_ready_for_payment, user: user }

          it 'sets the order back to address state' do
            do_request
            expect(Spree::Order.find_by(id: existing_order)).to be_nil
            expect(logged_out_order.reload.state).to eq 'address'
          end
        end

        context 'when the logging in user cart is in state :complete but no :completed_at' do
          let(:existing_order) { create :order_with_line_items, line_items_count: 2, user: user, state: :complete }

          it 'does not merge the cart' do
            expect { do_request }.not_to change(logged_out_order.line_items, :count)
            expect(Spree::Order.find_by(id: existing_order)).not_to be_nil
          end
        end

        context 'when carts have the same line_item variants' do
          let(:logged_out_li) { logged_out_order.line_items.first }
          let(:existing_order) do
            existing = create :order, store: logged_out_order.store, user: user
            existing.line_items << create(:line_item,
                                          variant: logged_out_li.variant,
                                          vendor: logged_out_li.vendor,
                                          price: logged_out_li.price)
            existing
          end

          context 'when the vendor is the same' do
            it 'increments the line item quantity' do
              expect { do_request }.not_to change(logged_out_order.line_items, :count)
              expect(logged_out_order.reload.line_items.first.quantity).to eq 2
            end
          end

          context 'when the vendor is different' do
            let(:vendor) do
              create(:vendor).tap { |v| v.prices.create!(variant: logged_out_li.variant, amount: logged_out_li.price) }
            end

            let(:existing_order) do
              existing = create :order, store: logged_out_order.store, user: user
              existing.line_items << create(:line_item,
                                            variant: logged_out_li.variant,
                                            vendor: logged_out_li.vendor,
                                            price: logged_out_li.price)
              existing
            end

            before { existing_order.line_items.first.update(vendor: vendor) }

            it 'creates a new line item' do
              expect { do_request }.to change(logged_out_order.line_items, :count).from(1).to 2
            end
          end
        end
      end
    end
  end
end

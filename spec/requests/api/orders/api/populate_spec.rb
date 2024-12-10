# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'add to cart of logged in user' do
  it 'responds with :ok HTTP status' do
    post_populate
    expect(response).to have_http_status(:ok)
  end

  it 'creates a new order' do
    expect { post_populate }.to change(Spree::Order, :count).from(0).to(1)
  end

  it 'adds the order to the user' do
    expect { post_populate }.to change(user.orders, :count).from(0).to(1)
  end
end

RSpec.describe 'Carts API', type: :request do
  describe 'POST populate' do
    subject(:post_populate) { post '/api/orders/cart', headers: headers, params: params }

    let(:headers) { { 'ACCEPT' => 'application/json' } }
    let(:offer_settings) { create :offer_settings }
    let(:variant) { offer_settings.variant }
    let(:vendor) { offer_settings.vendor }
    let(:store) { create(:store) }
    let(:user) { create(:user) }

    let(:params) do
      {
        line_item: {
          variant_id: variant.id,
          vendor_id: vendor.id,
          quantity: 1
        }
      }
    end

    before { store }

    it 'responds with :ok HTTP status' do
      post_populate
      expect(response).to have_http_status :ok
    end

    it 'creates a new order' do
      expect { post_populate }.to change(Spree::Order, :count).from(0).to(1)
    end

    context 'when not logged in' do
      before { order }

      context 'when a user_id is provided' do
        let(:order) { create :order, user: user, store: store }
        let(:params) { super().merge(user_id: user.id) }

        it 'creates a new order' do
          expect { post_populate }.to change(Spree::Order, :count).from(1).to(2)
        end

        it "doesn't attach order to the provided user id" do
          expect { post_populate }.not_to change(user.orders, :count).from(1)
        end
      end

      context 'when providing a user_id and order token of an existing order' do
        let(:order) { create :order, user: user, guest_token: 'foo', store: store }
        let(:params) { super().merge(order_token: order.guest_token, user_id: user.id) }

        it 'creates a new order for the guest user' do
          expect { post_populate }.to change(Spree::Order, :count).from(1).to(2)
          expect(Spree::Order.last.user).to be_nil
        end

        it 'does not create a new order not using the provided guest token' do
          expect { post_populate }.to change(Spree::Order, :count).from(1).to(2)
          expect(Spree::Order.last.guest_token).not_to eq order.guest_token
        end

        it 'does not add line items to the existing order' do
          expect { post_populate }.not_to change(order.line_items, :count)
        end
      end

      context 'when adding to an existing order' do
        let(:order) { create :order, guest_token: 'foo', store: store, user: nil }

        context 'with an Order Token header' do
          let(:headers) do
            {
              'ACCEPT' => 'application/json',
              'X-Spree-Order-Token' => order.guest_token
            }
          end

          it 'responds with :ok HTTP status' do
            post_populate
            expect(response).to have_http_status(:ok)
          end

          it 'does not create a new order' do
            expect { post_populate }.not_to change(Spree::Order, :count)
          end
        end

        context 'with an Order Token param' do
          let(:params) { super().merge(order_token: order.guest_token) }

          it 'responds with :ok HTTP status' do
            post_populate
            expect(response).to have_http_status(:ok)
          end

          it 'does not create a new order' do
            expect { post_populate }.not_to change(Spree::Order, :count)
          end

          context 'when order at address state has line items variants without prices' do
            let(:order) { create :order_with_line_items, guest_token: 'foo', store: store, user: nil, state: :address }

            it 'returns an out of stock error when the variant is out of stock' do
              variant = order.line_items.first.variant
              variant.prices = []
              variant.stock_items.first.set_count_on_hand(0)
              error_message = I18n.t('spree.checkout.errors.out_of_stock_items')

              post_populate

              expect(json_response).to match hash_including('error', error: error_message)
            end

            it 'returns an out of stock error when the variant is in stock' do
              variant = order.line_items.first.variant
              variant.prices = []
              error_message = 'Price is not valid and Vendor there are no price for this vendor'

              post_populate

              expect(json_response).to match hash_including('message', message: error_message)
            end
          end
        end
      end
    end

    context 'when logged in' do
      let(:headers) do
        {
          'ACCEPT' => 'application/json',
          'Authorization' => "Bearer #{user.spree_api_key}"
        }
      end

      it_behaves_like 'add to cart of logged in user'

      context 'when the user has an order' do
        let!(:order) { create :order_with_line_items, user: user, store: store }

        it 'creates a new order' do
          expect { post_populate }.not_to change(Spree::Order, :count)
        end

        it 'adds a line item to the user order' do
          expect { post_populate }.to change(order.line_items, :count).from(1).to(2)
        end
      end

      context 'when providing a bad order token' do
        let!(:order) { create :order_with_line_items, user: user, store: store }
        let(:params) { super().merge(order_token: 'foobar') }

        it 'does not create a new order' do
          expect { post_populate }.not_to change(Spree::Order, :count)
        end

        it 'adds a line item to the existing user order' do
          expect { post_populate }.to change(order.line_items, :count).from(1).to(2)
        end
      end
    end

    context 'when a custom Forwarded For header is provided' do
      let(:headers) { super().merge('X-Forwarded-For' => custom_ip) }
      let(:custom_ip) { FFaker::Internet.ip_v4_address }

      it 'sets the custom ip' do
        post_populate
        expect(Spree::Order.first.last_ip_address).to eq custom_ip
      end
    end

    context 'when browser analytics params are present' do
      let(:params) do
        super().merge(
          browser: {
            ab_tests: 'someabtest',
            amplitude_active: 'true',
            ga_active: 'false',
            maisonette_session_token: 'abc123'
          }
        )
      end

      it 'adds browser analytics json to the order' do
        post_populate

        browser_analytics = JSON.parse Spree::Order.last.browser_analytics
        expect(browser_analytics['ab_tests']).to eq 'someabtest'
        expect(browser_analytics['amplitude_active']).to eq 'true'
        expect(browser_analytics['ga_active']).to eq 'false'
        expect(browser_analytics['maisonette_session_token']).to eq 'abc123'
      end
    end
  end
end

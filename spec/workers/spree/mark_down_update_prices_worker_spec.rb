# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::MarkDownUpdatePricesWorker do
  let(:mark_down_id) { 5 }
  let(:mark_down) { instance_double Spree::MarkDown, id: mark_down_id, sale_prices: [sale_price], title: 'a mark down' }
  let(:sale_price) { instance_double Spree::SalePrice }
  # rubocop:disable RSpec/VerifiedDoubles
  let(:update_on_sale_context) { double Interactor::Context, failure?: failure?, message: error_message }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:failure?) {}
  let(:error_message) {}
  let(:send_updated_email_mailer) { instance_double ActionMailer::MessageDelivery, deliver_later: true }
  let(:send_updated_error_email_mailer) { instance_double ActionMailer::MessageDelivery, deliver_later: true }

  before do
    allow(Spree::MarkDown).to receive(:find).with(mark_down_id).and_return(mark_down)
    allow(mark_down).to receive(:update_sale_prices_cost_price).with([sale_price])
    allow(MarkDown::UpdateOnSaleInteractor).to(receive(:call).and_return(update_on_sale_context))
    allow(Spree::MarkDownUpdatePricesMailer).to(
      receive_messages(send_updated_email: send_updated_email_mailer,
                       send_updated_error_email: send_updated_error_email_mailer)
    )
    allow(Sentry).to receive(:capture_exception_with_message)

    described_class.new.perform(mark_down_id)
  end

  it 'calls MarkDown::UpdateOnSaleInteractor' do
    expect(MarkDown::UpdateOnSaleInteractor).to have_received(:call).with(mark_down: mark_down)
  end

  it 'update sale price cost price' do
    expect(mark_down).to have_received(:update_sale_prices_cost_price).with([sale_price])
  end

  context 'when it is successful' do
    let(:failure?) { false }

    it 'calls Spree::MarkDownUpdatePricesMailer.send_updated_email' do
      expect(Spree::MarkDownUpdatePricesMailer).to have_received(:send_updated_email).with(mark_down.title)
      expect(send_updated_email_mailer).to have_received(:deliver_later)
    end
  end

  context 'when it fails' do
    let(:failure?) { true }
    let(:error_message) { 'something went wrong!' }

    it 'captures an exception via Sentry' do
      expect(Sentry).to(
        have_received(:capture_exception_with_message)
          .with(Spree::UpdatePricesException.new(I18n.t("spree.#{error_message}")))
      )
    end

    it 'calls Spree::MarkDownUpdatePricesMailer.send_updated_error_email' do
      expect(Spree::MarkDownUpdatePricesMailer).to have_received(:send_updated_error_email).with(mark_down.title)
      expect(send_updated_error_email_mailer).to have_received(:deliver_later)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ImportShopsAndOffersWorker do
  let(:import_shops_worker) { instance_double(Mirakl::ImportShopsWorker, perform: true) }
  let(:updated_since) { Time.current }

  before do
    allow(Mirakl::ImportShopsWorker).to receive_messages(new: import_shops_worker)
    allow(Mirakl::ImportOffersWorker).to receive_messages(perform_async: true)

    described_class.new.perform
  end

  it 'calls perform on shops and offers worker' do
    expect(Mirakl::ImportShopsWorker).to have_received(:new)
    expect(import_shops_worker).to have_received(:perform)
    expect(Mirakl::ImportOffersWorker).to have_received(:perform_async)
  end
end

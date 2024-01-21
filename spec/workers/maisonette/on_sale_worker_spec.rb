# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::OnSaleWorker do
    before do
    allow(Maisonette::OnSaleInteractor).to(receive(:call!).and_return(true))

    described_class.new.perform
  end

  it 'calls Maisonette::OnSaleInteractor' do
    expect(Maisonette::OnSaleInteractor).to have_received(:call!)
  end
end

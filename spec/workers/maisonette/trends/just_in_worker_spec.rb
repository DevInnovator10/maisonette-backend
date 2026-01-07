# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::JustInWorker do
  before do
    allow(Maisonette::Trends::JustInOrganizer).to(receive(:call!).and_return(true))

    described_class.new.perform
  end

  it 'calls Maisonette::Trends::JustInOrganizer' do
    expect(Maisonette::Trends::JustInOrganizer).to have_received(:call!)
  end
end

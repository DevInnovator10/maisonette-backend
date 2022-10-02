# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cartonization::PackShipmentOrganizer do
  it { expect(described_class.new).to be_a Interactor::Organizer }

  it 'organizes paccurate interactors' do
    expect(described_class.organized).to eq([Cartonization::PrepareCartonizationInteractor,
                                             Cartonization::ShipsAloneInteractor,
                                             Cartonization::MailerInteractor,
                                             Cartonization::PaccurateInteractor])
  end
end

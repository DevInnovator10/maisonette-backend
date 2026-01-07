# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::CreateOrderWithShipmentsOrganizer, narvar: true do
  it { expect(described_class.new).to be_a Interactor::Organizer }

  it 'calls the required interactors' do
    expect(described_class.organized).to(
      include(
        Narvar::CreateOrderInteractor,
        Narvar::UpdateShipmentsInteractor
      )
    )
  end
end

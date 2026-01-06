# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::SendLabelsOrganizer, mirakl: true do
  it { expect(described_class.new).to be_a Interactor::Organizer }

  it do
    expect(described_class.organized).to eq([Mirakl::Easypost::SendLabels::DeleteLabelsInteractor,
                                             Mirakl::Easypost::SendLabels::BuyOrderInteractor,
                                             Mirakl::Easypost::SendLabels::BuyReturnInteractor,
                                             Mirakl::Easypost::SendLabels::CombineLabelsInteractor])

  end
end

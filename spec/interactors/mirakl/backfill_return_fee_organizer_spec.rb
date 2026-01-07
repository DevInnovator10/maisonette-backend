# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::BackfillReturnFeeOrganizer, mirakl: true do
  it { expect(described_class.new).to be_a Interactor::Organizer }
  it do
    expect(described_class.organized).to(
      eq [Mirakl::BackfillReturnFeeForVendorsInteractor,
          Mirakl::BuildReturnFeePayloadInteractor,
          Mirakl::SubmitOrderAdditionalFieldsInteractor]
    )
  end
end

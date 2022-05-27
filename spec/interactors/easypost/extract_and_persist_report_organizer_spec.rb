# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::ExtractAndPersistReportOrganizer do
  it { expect(described_class.new).to be_a Interactor::Organizer }

  it do
    expect(described_class.organized).to(
      eq [Easypost::ExtractReportInteractor,
          Easypost::PersistReportInteractor]
    )
  end
end

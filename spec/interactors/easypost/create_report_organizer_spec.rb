# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::CreateReportOrganizer do
  it { expect(described_class.new).to be_a Interactor::Organizer }

  it do
    expect(described_class.organized).to(
      eq [Easypost::CreateRemoteReportInteractor,
          Easypost::CreateLocalReportInteractor]
    )
  end
end

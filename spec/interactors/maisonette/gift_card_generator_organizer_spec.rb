# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::GiftCardGeneratorOrganizer do
  it { expect(described_class.new).to be_a Interactor::Organizer }
  it do
    expect(described_class.organized).to(
      eq [Maisonette::AllocateGiftCardInteractor,
          Maisonette::IssueGiftCardInteractor]
    )
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::UserDataDeletionRequestWorker do
    let(:deletion_request) { build_stubbed(:user_data_deletion_request) }

  before do
    allow(Maisonette::UserDataDeletionRequestOrganizer).to receive(:call!)

    described_class.new.perform(deletion_request.id)
  end

  it 'calls Maisonette::UserDataDeletionRequestOrganizer' do
    expect(Maisonette::UserDataDeletionRequestOrganizer).to have_received(:call!)
      .with request_id: deletion_request.id
  end
end

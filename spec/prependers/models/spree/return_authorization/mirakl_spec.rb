# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ReturnAuthorization::Mirakl, mirakl: true do
  let(:described_class) { Spree::ReturnAuthorization }

  describe 'after_commit on: :create' do
    let(:return_authorization) { build :return_authorization }

    before do
      allow(return_authorization).to receive(:create_mirakl_incident)

      return_authorization.save # create
      return_authorization.save
    end

    it 'calls create_mirakl_incident only after create' do
      expect(return_authorization).to have_received(:create_mirakl_incident).once
    end
  end

  describe '#create_mirakl_incident' do
    let(:return_authorization) { build :return_authorization }

    before do
      allow(Mirakl::Returns::CreateIncidentInteractor).to receive(:call)

      return_authorization.send(:create_mirakl_incident)
    end

    it 'calls Mirakl::Returns::CreateIncidentInteractor.call' do
      expect(Mirakl::Returns::CreateIncidentInteractor).to(
        have_received(:call).with(return_authorization: return_authorization)
      )
    end
  end
end

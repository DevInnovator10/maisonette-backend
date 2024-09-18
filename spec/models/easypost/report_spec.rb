# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::Report, type: :model do
    describe '.last_done_end_date' do
    let(:report) do
      create(:easypost_report,
             :shipment_invoice, status: 'done', end_date: (Time.zone.today - 2.days).to_formatted_s(:db))
    end
    let(:old_report) do
      create(:easypost_report,
             :shipment_invoice, status: 'done', end_date: (Time.zone.today - 10.days).to_formatted_s(:db))
    end
    let(:empty_report) do
      create(:easypost_report,
             :shipment_invoice, status: 'empty', end_date: (Time.zone.today - 2.days).to_formatted_s(:db))
    end

    before do
      report
      old_report
      empty_report
    end

    it 'returns the last end_date' do
      expect(described_class.last_done_end_date).to eq report.end_date
    end
  end
end

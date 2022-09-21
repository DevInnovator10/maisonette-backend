# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Video, type: :model do
  describe 'constants' do
    subject { described_class }

    it { is_expected.to be_const_defined(:EXTENSIONS) }
  end

  describe 'attachments' do
    it { is_expected.to have_attached_file(:attachment) }
    it { is_expected.to validate_attachment_presence(:attachment) }
    it { is_expected.to validate_attachment_content_type(:attachment).allowing('video/mp4').rejecting('image/png') }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:source_url).scoped_to [:viewable_id, :viewable_type] }
  end
end

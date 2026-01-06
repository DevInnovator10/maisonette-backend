# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::UserDataDeletionRequest, type: :model do
  subject { create(:user_data_deletion_request) }

  it { is_expected.to belong_to(:user).class_name('Spree::User') }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_uniqueness_of(:user_id) }
end

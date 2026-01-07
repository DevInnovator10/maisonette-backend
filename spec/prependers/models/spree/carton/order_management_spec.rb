# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Carton::OrderManagement, type: :model do
    let(:described_class) { Spree::Carton }

  it { is_expected.not_to validate_presence_of(:shipped_at) }
end

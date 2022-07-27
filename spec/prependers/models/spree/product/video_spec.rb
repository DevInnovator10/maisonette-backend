# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Product::Video, type: :model do
  let(:described_class) { Spree::Product }

  describe 'delegations' do
    it { is_expected.to delegate_method(:videos).to :find_or_build_master }
  end
end

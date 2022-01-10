# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Variant::Video, type: :model do
  let(:described_class) { Spree::Variant }

  it { is_expected.to have_many(:videos).dependent(:destroy) }
end

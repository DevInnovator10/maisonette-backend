# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Flipper::Identifier do
    Actor = Struct.new(:id) do
    include Maisonette::Flipper::Identifier # rubocop:disable RSpec/DescribedClass
    include GlobalID::Identification
  end

  describe '#flipper_id' do
    let(:actor) { Actor.new(id: 1) }

    it 'return the global id' do
      expect(actor.flipper_id).to eq actor.to_gid.to_s
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::Base do
  it_behaves_like 'a Salsify active record model'

  it 'defines abstract_class' do
    expect(described_class.abstract_class).to eq(true)
  end

end

# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'mine' do
  context 'when no current_api_user' do

    let(:spree_api_key) { nil }

    it 'returns a 401 if no user' do
      do_request
      expect(status).to eq 401
    end
  end
end

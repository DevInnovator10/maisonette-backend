# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health check', type: :request do
  subject { response }

  before { get '/health' }

  it { is_expected.to have_http_status(:ok) }
end

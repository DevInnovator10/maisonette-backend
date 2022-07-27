# frozen_string_literal: true

module MineConcerns
  extend ActiveSupport::Concern

  included do
    before_action :verify_current_api_user, only: :mine
  end

  def mine
    raise 'define #mine in controller'
  end

  private

  def verify_current_api_user
    unauthorized unless current_api_user
  end
end

# frozen_string_literal: true

module Easypost
  class Report < Easypost::Base
    enum status: {
      requested: 'new',
      available: 'available',
      empty: 'empty',
      done: 'done'
    }
    def self.last_done_end_date
      done.order(end_date: :desc).select(:end_date).first&.end_date
    end
  end
end

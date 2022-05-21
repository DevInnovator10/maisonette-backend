# frozen_string_literal: true

module Orders
  class ReturnPolicyInteractor < ApplicationInteractor
    STANDARD_RETURN_POLICY   = 30.days
    HOLIDAY_START_DAY        = 1
    HOLIDAY_START_MONTH      = 11
    HOLIDAY_END_DAY          = 15
    HOLIDAY_END_MONTH        = 12
    HOLIDAY_RETURN_END_DAY   = 15
    HOLIDAY_RETURN_END_MONTH = 1

    before :validate_context

    def call
      context.comply_with_return_policy = comply_with_standard_return_policy? ||
                                          comply_with_holiday_return_policy?
    end

    private

    def comply_with_standard_return_policy?
      completed_at >= STANDARD_RETURN_POLICY.ago.beginning_of_day
    end

    def comply_with_holiday_return_policy?
      Time.zone.now.before?(holiday_return_expiration_date) &&
        completed_at.between?(holiday_start_date, holiday_end_date)
    end

    def holiday_start_date
      Date.new(completed_at.year,
               HOLIDAY_START_MONTH,
               HOLIDAY_START_DAY).beginning_of_day
    end

    def holiday_end_date
      Date.new(completed_at.year,
               HOLIDAY_END_MONTH,
               HOLIDAY_END_DAY).end_of_day
    end

    def holiday_return_expiration_date
      Date.new(completed_at.year + 1,
               HOLIDAY_RETURN_END_MONTH,
               HOLIDAY_RETURN_END_DAY).end_of_day
    end

    def validate_context
      context.fail!(message: 'Missing order completed at date') unless context.order&.completed_at
    end

    def completed_at
      context.order&.completed_at
    end
  end
end

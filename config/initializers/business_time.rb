# frozen_string_literal: true

Holidays.between(Time.zone.parse('2021-01-01'), 2.years.from_now, :us).map do |holiday|
    BusinessTime::Config.holidays << holiday[:date]
end

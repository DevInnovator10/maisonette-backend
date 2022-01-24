# frozen_string_literal: true

module DateHelper
  def date_ymd(date)
    date.nil? ? '' : date.strftime('%Y-%m-%d')

  end

  def date_mdy(date)
    date.nil? ? '' : date.strftime('%b %d, %Y')
  end
end

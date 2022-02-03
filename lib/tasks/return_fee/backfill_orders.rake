# frozen_string_literal: true

namespace :return_fee do
  desc 'backfill order with their return fee'
  task backfill_orders: :environment do
    from_date = from_date("provide a starting date to backfill orders ex: '31-10-2022'")
    to_date = to_date("provide ending date to backfill orders ex: '31-10-2022'")
    orders = get_orders_to_be_backfilled_with_return_fee(from_date, to_date)
    puts "#{orders.size} orders will be processed"
    orders.each do |order|
      Mirakl::BackfillReturnFeeOrganizer.call(mirakl_order: order)
    end
  end

  desc 'create Easypost::Tracker for every return_authorization that does not has one'
  task create_trackers: :environment do
    from_date = from_date("provide a starting date to associate trackers to authorizations ex: '31-10-2022'")
    to_date = to_date("provide ending date to associate trackers to authorizations orders ex: '31-10-2022'")
    return_authorizations = get_return_authorizations_to_be_associated_with_easypost_trackers(from_date, to_date)
    puts "#{return_authorizations.size} trackers will be created"
    return_authorizations.each do |authorization|
      Easypost::AssociateTrackerToReturnAuthorizationInteractor.call(authorization: authorization)
    end
  end
end

def get_orders_to_be_backfilled_with_return_fee(from, to)
  Mirakl::Order.joins(:order_line_reimbursements, :order_lines)
               .includes(:order_line_reimbursements, :order_lines)
               .where('mirakl_order_lines.return_fee = ?', 0.0)
               .where('mirakl_order_lines.return_authorization_id IS NOT NULL')
               .where('mirakl_order_line_reimbursements.created_at BETWEEN ? AND ?', from, to)
end

def get_return_authorizations_to_be_associated_with_easypost_trackers(from, to)
  # rubocop:disable Metrics/LineLength
  Spree::ReturnAuthorization.where(created_at: from..to)
                            .where.not(tracking_url: nil)
                            .where('easypost_trackers.spree_return_authorization_id IS NULL')
                            .joins('LEFT JOIN easypost_trackers ON spree_return_authorizations.id = easypost_trackers.spree_return_authorization_id')
  # rubocop:enable Metrics/LineLength
end

def from_date(msg)
  done = from = false
  while !done
    puts msg
    from = done = from_date_from_customer
  end
  from
end

def to_date(msg)
  done = to = false
  while !done
    puts "#{msg}, or enter NO to take today's date as the ending date"
    to = done = to_date_from_customer
  end
  to
end

def from_date_from_customer
  from_date = STDIN.gets.chomp
  Date.parse(from_date).beginning_of_day
rescue Date::Error
  puts "#{from_date} is not a valid date please provide a valid one"
  false
end

def to_date_from_customer
  to_date = STDIN.gets.chomp
  if to_date.downcase == 'no'
    puts "#{Time.zone.today} was chosen"
    return Time.zone.today.end_of_day
  end
  Date.parse(to_date).end_of_day
rescue Date::Error
  puts "#{to_date} is not a valid date please provide a valid one"
  false
end

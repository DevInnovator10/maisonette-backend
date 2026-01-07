# frozen_string_literal: true

puts 'Remove useless shipping methods'
Spree::ShippingMethod.where(id: [16, 8, 6, 11, 10]).destroy_all
puts 'Remove useless shipping category'
Spree::ShippingCategory.select { |sc| sc.shipping_methods.empty? }.each(&:destroy)

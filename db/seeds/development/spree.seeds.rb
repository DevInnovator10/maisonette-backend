# frozen_string_literal: true

%w[
  return_reasons
  refund_reasons
].each do |seed|
  puts "Loading seed file: #{seed}"
  require_relative "../../default/spree/#{seed}"
end

Spree::Auth::Engine.load_seed if defined?(Spree::Auth)

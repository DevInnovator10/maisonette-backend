# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:example, :subscriber) do |e|
    Spree::Event.deactivate_all_subscribers
    e.metadata[:described_class].activate
    e.run
    Spree::Event.activate_all_subscribers
  end
end

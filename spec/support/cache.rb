# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :cache) do |example|
    previous_conf = ActionController::Base.perform_caching

    ActionController::Base.perform_caching = example.metadata[:cache]
    example.run
    ActionController::Base.perform_caching = previous_conf
  end

  config.before(:each, cache: false) do
    allow(Rails).to receive(:cache) { ActiveSupport::Cache::NullStore.new }
  end
end

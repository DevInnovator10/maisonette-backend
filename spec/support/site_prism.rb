# frozen_string_literal: true

require 'selenium-webdriver'
require 'site_prism'
require 'capybara'

Dir[Rails.root.join('spec/sections/**/*.rb')].each { |f| require f }

Dir[Rails.root.join('spec/pages/**/*.rb')].each { |f| require f }

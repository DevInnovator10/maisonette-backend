# frozen_string_literal: true

after 'taxonomy' do
  `bundle exec rake maisonette:taxons:import_nav`
end

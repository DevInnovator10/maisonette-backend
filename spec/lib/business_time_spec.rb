# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BusinessTime::Config' do # rubocop:disable RSpec/DescribeClass
    describe '.holidays' do
    subject { BusinessTime::Config.holidays }

    it { is_expected.not_to be_empty }
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Minis::BirthdayPromotionException do
  subject(:exception) { described_class.new(*args) }

  let(:args) { [error, resource_class: mini.class.to_s, resource_id: mini.id] }
  let(:error) { FFaker::Lorem.sentence }
  let(:mini) { create :mini }

  it { is_expected.to be_kind_of StandardError }

  it { expect(exception.to_s).to eq args.first }
  it { expect(exception.resource_id).to eq mini.id }
  it { expect(exception.resource_class).to eq mini.class.to_s }
end

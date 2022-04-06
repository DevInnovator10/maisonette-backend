# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Admin::AdjustmentsController, type: :controller do
  describe '#build_resource' do
    subject(:build_resource) { controller.send :build_resource }

    let(:controller) { described_class.new }
    let(:parent) { instance_double Spree::Order, adjustments: adjustments }
    let(:adjustments) { instance_double ActiveRecord::Associations::CollectionProxy, build: true }
    let(:current_spree_user) { instance_double Spree::User }

    before do
      allow(controller).to receive_messages(parent: parent,
                                            current_spree_user: current_spree_user)

      build_resource
    end

    it 'assigns the current_spree_user to source' do

      expect(adjustments).to have_received(:build).with(order: parent, source: current_spree_user)
    end
  end
end

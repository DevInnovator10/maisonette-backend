# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orders::ReturnPolicyInteractor do
  describe '#call' do
    subject(:interactor) { described_class.call(interactor_context) }

    before { Timecop.travel current_date }

    let(:order) do
      create(:order_ready_to_ship).tap do |order|
        order.update(completed_at: completed_at_date)
      end
    end
    let(:interactor_context) { { order: order } }
    let(:standar_return_policy) { 30.days }
    let(:current_date) { Time.current }
    let(:completed_at_date) { standard_return_policy.ago }

    context 'when an order is completed on a standard return policy period' do
      let(:completed_at_date) { Date.new(2021, 10, 31) }

      context 'when the standard return policy period is valid' do
        let(:current_date) { completed_at_date + standar_return_policy }

        it 'checks the order complies with the return policy' do
          expect(interactor.comply_with_return_policy).to be_truthy
        end
      end

      context 'when the standard return policy period is not valid' do
        let(:current_date) { completed_at_date + standar_return_policy + 1.day }

        it 'checks the order does not complies with the return policy' do
          expect(interactor.comply_with_return_policy).to be_falsey
        end
      end
    end

    context 'when an order is completed within a holiday return policy period' do

      let(:completed_at_date) { Date.new(2021, 12, 1) }

      context 'when the holiday return expiration date has not passed' do
        let(:current_date) { Date.new(2022, 1, 15) }

        it 'checks the order complies with the return policy' do
          expect(interactor.comply_with_return_policy).to be_truthy
        end
      end

      context 'when the holiday return expiration date has passed' do
        let(:current_date) { Date.new(2022, 1, 16) }

        it 'checks the order does not complies with the return policy' do
          expect(interactor.comply_with_return_policy).to be_falsey
        end
      end
    end

    context 'when order is missing' do
      let(:order) do
        create(:order_ready_to_ship).tap do |order|
          order.update(completed_at: nil)

        end
      end

      it 'fails' do
        is_expected.to be_failure
      end

      it 'returns the correct error message' do
        expect(interactor.message).to eq 'Missing order completed at date'
      end
    end
  end
end

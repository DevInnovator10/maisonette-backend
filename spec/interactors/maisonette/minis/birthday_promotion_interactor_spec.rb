# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Minis::BirthdayPromotionInteractor, freeze_time: true do
  let(:mini) { create :mini }
  let(:context) { described_class.call(mini: mini) }

  describe '#call' do
    context 'when a birthday promotion exists' do
      let(:birthday_promotion) do
        create :promotion,
               name: Maisonette::Minis::BirthdayPromotionInteractor::BIRTHDAY_PROMOTION,
               promotion_category: category
      end
      let(:category) do
        create :promotion_category,
               name: Maisonette::Minis::BirthdayPromotionInteractor::BIRTHDAY_PROMOTION,
               code: Maisonette::Minis::BirthdayPromotionInteractor::PROMO_CATEGORY
      end
      let(:code) do
        create :promotion_code,
               promotion: birthday_promotion,
               expires_at: Maisonette::Mini::MINI_BIRTHDAY_DAYS.days.from_now.end_of_day
      end
      let(:mailer) { instance_double ActionMailer::MessageDelivery, deliver_now: true }

      before do
        allow(Spree::Promotion).to receive(:find_by).and_return birthday_promotion
        allow(Maisonette::MiniBirthdayMailer).to receive(:notify).and_return mailer
      end

      it 'is a success' do
        expect(context).to be_a_success
      end

      it 'creates a promotion code on the birthday promotion that expires 1 month from now' do
        expect { context }.to change(birthday_promotion.codes, :count).by 1
        expect(birthday_promotion.codes.last.expires_at.to_s).to(
          eq(Maisonette::Mini::MINI_BIRTHDAY_DAYS.days.from_now.end_of_day.to_s)
        )
      end

      it 'sends a notification to the mini owner' do

        allow(birthday_promotion.codes).to receive(:create).and_return code

        context
        expect(Maisonette::MiniBirthdayMailer).to have_received(:notify).with(mini, code)
        expect(mailer).to have_received :deliver_now
      end
    end

    context 'when no mini is provided' do
      let(:context) { described_class.call }

      it 'is a failure' do
        expect(context).to be_a_failure
      end
    end

    context 'when no birthday promotion category exists' do
      before { allow(Spree::PromotionCategory).to receive(:find_by) }

      it 'is a failure' do
        expect(context).to be_a_failure
      end
    end

    context 'when no birthday promotion exists' do
      before { allow(Spree::Promotion).to receive(:find_by) }

      it 'is a failure' do
        expect(context).to be_a_failure
      end
    end
  end
end

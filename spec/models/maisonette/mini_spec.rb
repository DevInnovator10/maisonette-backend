# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Mini, type: :model do
  let(:mini_parent) { create :user }
  let(:yesterday) { 1.day.ago }

  describe 'constants' do
    subject { described_class }

    it { is_expected.to be_const_defined(:MINI_BIRTHDAY_DAYS) }
    it { is_expected.to be_const_defined(:MINI_PAST_YEARS_THRESHOLD) }
    it { is_expected.to be_const_defined(:MINI_FUTURE_MONTHS_THRESHOLD) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:gender_taxons).to :personalization }
    it { is_expected.to delegate_method(:age_range_taxons).to :personalization }
    it { is_expected.to delegate_method(:baby?).to :personalization }
  end

  describe 'validations' do
    let(:mini) do
      build :mini,
            user: mini_parent,
            name: 'Penny',
            birth_year: birth_year,
            birth_month: birth_month,
            birth_day: birth_day
    end
    let(:birth_date) { (Time.current - 1.year).beginning_of_month }
    let(:birth_year) { birth_date.year }
    let(:birth_month) { birth_date.month }
    let(:birth_day) { birth_date.day }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:birth_year) }
    it { is_expected.to validate_presence_of(:birth_month) }

    describe 'validating calculated birthday' do
      context 'when the mini birth date is over 9 months into the future' do
        let(:birth_date) { 10.months.from_now }

        it 'fails validation' do
          expect(mini).not_to be_valid
          expect(mini.errors.messages[:calculated_birthday]).to(
            include I18n.t('errors.maisonette.mini.calculated_birthday')
          )

          mini.birth_month = 9.months.from_now.month
        end
      end

      context 'when the mini birth date is within 9 months' do
        let(:birth_date) { 9.months.from_now }

        it 'passed validation' do
          expect(mini).to be_valid
        end
      end

      context 'when the mini is over 16 years old' do
        let(:birth_date) { 16.years.ago }

        it 'fails validation' do
          expect(mini).not_to be_valid
          expect(mini.errors.messages[:calculated_birthday]).to(
            include I18n.t('errors.maisonette.mini.calculated_birthday')
          )
        end
      end

      context 'when the mini is under 16 years old' do
        let(:birth_date) { 15.years.ago }

        it 'passed validation' do
          expect(mini).to be_valid
        end
      end

      context 'with an existing record when the birthday is not changed' do
        let(:mini) do
          (create :mini, user: mini_parent, name: 'Penny', birth_year: yesterday.year).tap do |mini|
            mini.update_column(:birth_year, 30.years.ago.year)
          end
        end

        it 'is valid with a birth year older than 25 years' do
          expect(mini).to be_valid
        end

        it 'can update the name without validating the year' do
          mini.update!(name: 'foo')
          expect(mini).to be_valid
          expect(mini.birth_year).to eq 30.years.ago.year
        end

        it 'validates the year if the date is changed' do
          mini.update(birth_year: 31.years.ago.year)
          expect(mini).not_to be_valid
        end
      end
    end

    context 'when validating the birth month' do
      it 'must be between 1 and 12' do # rubocop:disable RSpec/MultipleExpectations
        mini.birth_month = 0
        expect(mini).not_to be_valid
        expect(mini.errors.messages[:birth_month]).to include I18n.t('errors.maisonette.mini.birth_month')

        mini.birth_month = 1
        expect(mini).to be_valid

        mini.birth_month = 12
        expect(mini).to be_valid

        mini.birth_month = 13
        expect(mini).not_to be_valid
        expect(mini.errors.messages[:birth_month]).to include I18n.t('errors.maisonette.mini.birth_month')
      end
    end

    context 'when validating the birth day' do
      it 'does not require a birth day' do
        expect(mini).to be_valid
      end

      it 'does not allow day 0 for any month' do
        (1..12).each do |month|
          mini.birth_month = month
          mini.birth_day = 0
          expect(mini).not_to be_valid
        end
      end

      context 'when validating february' do
        it 'considers leap years' do
          mini.birth_year = 2016
          mini.birth_month = 2
          mini.birth_day = 29
          expect(mini).to be_valid

          mini.birth_year = 2017
          expect(mini).not_to be_valid

          mini.birth_day = 28
          expect(mini).to be_valid
        end

        it 'is valid for february' do
          mini.birth_month = 2
          mini.birth_day = 1
          expect(mini).to be_valid

          mini.birth_day = 28
          expect(mini).to be_valid

          mini.birth_day = 30
          expect(mini).not_to be_valid
        end
      end

      it 'allows 30 days in april, june, september, and november' do
        [4, 6, 9, 11].each do |month|
          mini.birth_month = month
          mini.birth_day = 30
          expect(mini).to be_valid

          mini.birth_day = 31
          expect(mini).not_to be_valid
        end
      end

      it 'allows 31 days in january, march, may, july, august, october, and december' do
        [1, 3, 5, 7, 8, 10, 12].each do |month|
          mini.birth_month = month
          mini.birth_day = 31
          expect(mini).to be_valid
        end
      end
    end
  end

  describe '#set_birthday' do
    subject(:mini) { build(:mini, birth_date).tap(&:save) }

    context 'when given all of the date attributes' do
      let(:birth_date) { { birth_year: 2012, birth_month: 2, birth_day: 10 } }

      it 'sets the correct date' do
        expect(mini.calculated_birthday).to eq Date.new(2012, 2, 10).in_time_zone
      end
    end

    context 'when given month and year' do
      let(:birth_date) { { birth_year: 2012, birth_month: 2, birth_day: nil } }

      it 'sets the date to the end of the provided month' do
        expect(mini.calculated_birthday).to eq Date.new(2012, 2).in_time_zone.end_of_month.beginning_of_day
      end
    end

    context 'when not updating the date' do
      let(:existing_mini) { create :mini }

      before { allow(existing_mini).to receive :set_birthday }

      it 'does not change the calculated_birthdate' do
        existing_mini.update name: 'foo'
        expect(existing_mini).not_to have_received :set_birthday
      end
    end
  end

  describe '.with_birthday_near' do
    let(:bd_date) { Time.zone.today + described_class::MINI_BIRTHDAY_DAYS.days - 1.year }
    let(:bd_date_plus_1_day) { bd_date + 1.day }
    let(:bd_date_minus_1_day) { bd_date - 1.day }

    let(:mini_with_birthday_near) do
      create :mini,
             birth_day: bd_date.day,
             birth_month: bd_date.month,
             birth_year: bd_date.year
    end
    let(:mini_plus_1_day_from_birthday_near) do
      create :mini,
             birth_day: bd_date_plus_1_day.day,
             birth_month: bd_date_plus_1_day.month,
             birth_year: bd_date.year
    end
    let(:mini_minus_1_day_from_birthday_near) do
      create :mini,
             birth_day: bd_date_minus_1_day.day,
             birth_month: bd_date_minus_1_day.month,
             birth_year: bd_date.year
    end

    before do
      mini_with_birthday_near
      mini_plus_1_day_from_birthday_near
      mini_minus_1_day_from_birthday_near
    end

    it 'returns minis with a calculated birthday exactly MINI_DAYS away' do
      expect(described_class.with_birthday_near).to match_array [mini_with_birthday_near]
    end

    context 'when returning old minis' do
      let(:old_mini_with_birthday_near) do
        create :mini,
               birth_day: bd_date.day,
               birth_month: bd_date.month,
               birth_year: (described_class::MINI_PAST_YEARS_THRESHOLD - 1).years.ago.year
      end
      let(:too_old_mini) do
        create :mini,
               birth_day: bd_date.day,
               birth_month: bd_date.month,
               birth_year: bd_date.year # Set year in before hook, due to validations when we are near the new year
      end

      before do
        old_mini_with_birthday_near
        too_old_mini.update_column(:birth_year, described_class::MINI_PAST_YEARS_THRESHOLD.years.ago.year)
        too_old_mini.send :set_birthday
      end

      it 'returns minis with a birthday exactly MINI_DAYS away and up to 25 years old' do
        expect(described_class.with_birthday_near).to match_array [mini_with_birthday_near,
                                                                   old_mini_with_birthday_near]
      end
    end

    context 'when a future mini exists (not yet born)' do
      let(:future_birth_date) { bd_date + 1.year }

      let(:future_mini_with_birthday_near) do
        create :mini,
               birth_day: future_birth_date.day,
               birth_month: future_birth_date.month,
               birth_year: future_birth_date.year
      end

      before do
        future_mini_with_birthday_near
      end

      it 'returns minis with a birthday exactly MINI_DAYS away and not born yet' do
        expect(described_class.with_birthday_near).to match_array [mini_with_birthday_near,
                                                                   future_mini_with_birthday_near]
      end
    end

    context 'when the birth_day is nil' do
      let!(:mini4) do
        create :mini,
               birth_day: nil,
               birth_month: 1,
               birth_year: 2020
      end

      context 'when the birthday_near is the last day of the month', freeze_time: Time.zone.local(2020, 1, 3) do
        it 'includes the mini with birth_day nil' do
          expect(described_class.with_birthday_near).to include mini4
        end
      end

      context 'when the birthday_near is not last day of the month', freeze_time: Time.zone.local(2020, 1, 2) do
        it 'does not include the mini with birth_day nil' do
          expect(described_class.with_birthday_near).not_to include mini4
        end
      end
    end
  end
end

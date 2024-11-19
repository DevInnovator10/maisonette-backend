# frozen_string_literal: true

mini ||= @mini

json.call mini, :id, :user_id, :name, :birth_year, :birth_month, :birth_day,
            :gender_boy, :gender_girl, :gender_taxons, :age_range_taxons

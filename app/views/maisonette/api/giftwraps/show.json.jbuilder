# frozen_string_literal: true

giftwrap ||= @giftwrap

json.partial! 'maisonette/api/giftwraps/small', giftwrap: giftwrap

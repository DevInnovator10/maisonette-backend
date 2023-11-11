# frozen_string_literal: true

subscriber ||= @subscriber

json.partial! 'maisonette/api/subscribers/subscriber', subscriber: subscriber

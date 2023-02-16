# frozen_string_literal: true

subscriber ||= @subscriber

json.call(subscriber, :id, :user_id, :list_id, :email, :first_name, :last_name, :source, :phone, :status, :created_at)

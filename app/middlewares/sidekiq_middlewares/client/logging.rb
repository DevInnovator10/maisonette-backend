# frozen_string_literal: true

module SidekiqMiddlewares
  module Client
    class Logging
      def call(_worker, job, *)
        duped_job = job.deep_dup
        duped_job['args'].map!(&:to_s)
        class_name = duped_job['class']

        Rails.logger.tagged(class_name) do
          Rails.logger.info(sidekiq: duped_job, message: "sidekiq queueing: #{duped_job['class']}")
          yield
        end
      end
    end
  end
end

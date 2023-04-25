# frozen_string_literal: true

module SidekiqMiddlewares
  module Client
    class CorrelationTracer
      def call(_worker, job, *)
        return yield if defined?(Sidekiq::Testing) && Sidekiq::Testing.inline?
        return yield if job['args'].any? { |arg| arg.respond_to?(:keys) && arg.keys == %w[trace_id span_id] }

        job['lock_args'] = job['args'].deep_dup
        job['args'] << { 'trace_id' => Datadog.tracer.active_correlation.trace_id,
                         'span_id' => Datadog.tracer.active_correlation.span_id }
        yield
      end
    end
  end
end

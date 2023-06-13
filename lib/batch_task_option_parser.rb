# frozen_string_literal: true

class BatchTaskOptionParser
  attr_reader :solidus_model, :from, :to, :batch_size, :input

  def initialize(solidus_model, from, to, batch_size)
    @solidus_model = solidus_model
    @from = from
    @to = to
    @batch_size = batch_size.to_i
  end

  def perform!
    @solidus_model = solidus_model.constantize
    @from = from.to_date.beginning_of_day
    @to = to.to_date.end_of_day
    @batch_size = batch_size.zero? ? solidus_model.count : batch_size
    ask_confirmation
    wait_for_answer
  end

  def ask_confirmation
    STDOUT.puts "Processing #{solidus_model} from #{from} to #{to} in #{batch_size} batch, continue? (y/n)"
  end

  def wait_for_answer
    @input = STDIN.gets.strip
  end
end

# frozen_string_literal: true

class AppLogger # rubocop:todo Style/Documentation
  extend SingleForwardable

  def_delegators :logger, :debug, :info, :warn, :error, :fatal, :level=

  class << self
    attr_reader :logger

    def init(logger)
      @logger = logger
    end
  end
end

class AppLogger
  extend SingleForwardable

  def_delegators :logger, :debug, :info, :warn, :error, :fatal, :level=

  class << self
    attr_reader :logger

    def init logger
      @logger = logger
  end
  end
end
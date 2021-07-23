# frozen_string_literal: true

require 'sinatra/custom_logger'
require_relative 'app_logger'

class AppBase < Sinatra::Application # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/MethodLength
  def self.general_configure # rubocop:todo Metrics/AbcSize
    enable :sessions, :logging
    set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
    $stdout.sync = true

    helpers Sinatra::CustomLogger

    helpers do
      def h(text)
        Rack::Utils.escape_html(text)
      end

      def hattr(text)
        Rack::Utils.escape_path(text)
      end
    end

    configure :development, :production do
      FileUtils.mkdir_p "#{root}/log"
      file = File.open("#{root}/log/#{environment}.log", 'a+')
      file.sync = true
      logger = Logger.new(file)
      logger.level = development? ? Logger::INFO : Logger::WARN
      AppLogger.init logger

      set :logger, logger
    end

    configure :development do
      register Sinatra::Reloader
      also_reload "#{root}/lib/**/*.rb"
    end

    require "#{root}/config/initializers/autoloader.rb"
  end
  # rubocop:enable Metrics/MethodLength
end

require 'sinatra/custom_logger'
require_relative 'app_logger'

class AppBase < Sinatra::Application
 
 	def self.general_configure

    enable :sessions, :logging
    set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
    $stdout.sync = true

    helpers Sinatra::CustomLogger

    configure :development, :production do
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
end

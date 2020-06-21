# frozen_string_literal: true

paths = %w[config/initializers/*.rb lib/**/*.rb].map(&:freeze).freeze

paths.each do |path|
  Dir[File.join(AppBase.root, path)].each do |file|
    next if file.include?('initializers/autoloader') # skip me

    require file
  end
end

class AccessSettings
	attr_reader :domain, :api_token

	def initialize(source)
		@domain = normalize(source[:domain])
		@api_token = source[:api_token]
	end

	def valid?
		!!(@domain && @api_token && !@domain.empty? && !@api_token.empty?)
	end

	def store(target)
		target[:domain], target[:api_token] = @domain, @api_token
	end

	def to_s
		"you have domain #{@domain} and api key #{@api_token}!!"
	end

	private

	TLD = '.kanbantool.com'
	
	def normalize domain
		return domain if domain.nil? || domain.empty?

		domain += TLD unless domain.include?(TLD)
		domain
	end


end

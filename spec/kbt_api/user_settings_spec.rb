RSpec.describe AccessSettings, '#valid?' do
	context 'missing values from input' do
		it "nils should not be valid" do
			sut = AccessSettings.new({})
			expect(sut.valid?).to eq false
		end

		it "blanks should not be valid" do
			sut = AccessSettings.new({domain: '', api_token: ''})
			expect(sut.valid?).to eq false
		end

		it "partials should not be valid" do
			sut = AccessSettings.new({domain: 'abc'})
			expect(sut.valid?).to eq false
		end
	end

	context 'complete values in input' do
		it "should be valid" do
			sut = AccessSettings.new({domain: 'abc', api_token: 'AABB'})
			expect(sut.valid?).to eq true
		end
	end

	context 'store works' do
		it "output to store is same as input to initialize" do
			input = {domain: 'abc.kanbantool.com', api_token: 'AABB'}
			output = {}
			
			sut = AccessSettings.new(input)
			sut.store output
			
			expect(output).to eq input
		end
	end

	context 'store had kanbantool magic' do
		it "output to store has full domain" do
			input = {domain: 'abc', api_token: 'AABB'}
			input_with_full_domain = {domain: 'abc.kanbantool.com', api_token: 'AABB'}
			output = {}
			
			sut = AccessSettings.new(input)
			sut.store output
			
			expect(output).to eq input_with_full_domain
		end
	end
end
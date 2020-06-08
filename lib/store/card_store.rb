class CardStore

	@@cards = {}
	@@card_details = {}

	def initialize api
		@api = api
	end

	def find_card card_id
		card = @@cards[card_id] || @@card_details[card_id]

		return card if !card.nil? || @@cards.keys.include?(card_id)

		@@cards[card_id] = @api.card(card_id)
	end

	def find_card_detail card_id 
		@@card_details[card_id] ||= @api.card_detail(card_id)
	end

	def store_cards raw_cards
		@@cards.merge! raw_cards.to_h{|card| [card["id"].to_i, card]}
	end

end

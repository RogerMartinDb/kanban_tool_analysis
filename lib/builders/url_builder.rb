# frozen_string_literal: true

class UrlBuilder # rubocop:todo Style/Documentation
  def initialize(api, board_id)
    @api = api
    @board_id = board_id
  end

  def board_url
    @api.board_url @board_id
  end

  def card_url(card_id)
    @api.card_url @board_id, card_id
  end
end

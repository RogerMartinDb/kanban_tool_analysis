class UrlBuilder
  def initialize api, board_id
    @api, @board_id = api, board_id
  end

  def board_url
    @api.board_url @board_id
  end

  def card_url card_id
    @api.card_url @board_id, card_id
  end

end

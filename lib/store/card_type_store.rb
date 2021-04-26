class CardTypeStore

  def initialize(api)
    @api = api
  end

  def get_card_type(card_type_id, current_board)
    card_type = current_board.card_types[card_type_id]
    return card_type if card_type

    @@card_types ||= begin
      @api
        .current_user["boards"]
        .map{|raw_summary| @api.board(raw_summary['id'])}
        .map{|raw_board| Board.new(raw_board)}
        .map{|board| board.card_types}
        .each_with_object({}){|board_card_types, all_card_types| all_card_types.merge!(board_card_types)}
    end

    AppLogger.info "card types #{@@card_types}"

    @@card_types[card_type_id] || {
      'name' => card_type_id,
      'color_attrs' => { 'rgb' => 'white', 'invert' => false }
    }
  end
end

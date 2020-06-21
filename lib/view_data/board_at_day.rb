module ViewData
  class BoardAtDay # rubocop:todo Style/Documentation
    attr_reader :date

    def initialize(api, board_id, date)
      @date = date

      @history = HistoryBuilder.new api, board_id, @date..@date
      @url_builder = UrlBuilder.new api, board_id
    end

    def board_name
      @history.board.name
    end

    def stages
      by_stage_id = @history.card_histories_by_stage_id

      stages = by_stage_id.map  do |stage_id, cards|
        stage = decorate_stage(stage_id)
        stage[:cards] = decorate_cards(cards)
        stage
      end

      stages.sort { |a, b| a[:order] <=> b[:order] }
    end

    private

    def decorate_stage(stage_id)
      stage = @history.board.workflow_stages[stage_id]

      stage ||= { 'full_name' => 'other board', 'lft' => 1_000_000 }

      {
        id: stage_id,
        name: stage['full_name'].sub(' / ', ': '),
        order: stage['lft']
      }
    end

    # rubocop:todo Metrics/MethodLength
    def decorate_cards(cards) # rubocop:todo Metrics/AbcSize
      cards.map do |card|
        card_type = card_type(card.card_type_id)

        {
          name: card.name,
          card_type_id: card.card_type_id,
          color: card_type['color_attrs']['rgb'],
          invert: !!card_type['color_attrs']['invert'], # rubocop:todo Style/DoubleNegation
          url: @url_builder.card_url(card.id)
        }
      end
           .sort { |a, b| b[:card_type_id] <=> a[:card_type_id] }
    end
    # rubocop:enable Metrics/MethodLength

    def card_type(card_type_id)
      card_types = @history.board.card_types

      card_types[card_type_id] || {
        'color_attrs' => { 'rgb' => 'white', 'invert' => false }
      }
    end
  end
end

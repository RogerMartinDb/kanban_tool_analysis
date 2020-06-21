# frozen_string_literal: true

module ViewData
  # rubocop:todo Style/Documentation
  class WorkInPeriod # rubocop:todo Metrics/ClassLength
    attr_reader :period

    def initialize(api, board_id, period)
      @period = period

      history = HistoryBuilder.new api, board_id, period

      @work = WorkBuilder.new period, history
      @board = history.board
      @url_builder = UrlBuilder.new api, board_id
    end

    def board_name
      @board.name
    end

    def board_description
      @board.description
    end

    def start
      @period.begin.strftime('%d %b')
    end

    def finish
      period.end.strftime('%d %b')
    end

    def board_url
      @url_builder.board_url
    end

    def work_done
      cards = @work.work_done_in_period.each do |card|
        decorate card
      end

      to_list_of_lists cards, :cards do |card|
        { card_type_name: card[:card_type_name] }
      end
    end

    def work_by_card_types
      @work.card_types_in_order_of_work.map  do |card_type_id|
        card_type = get_card_type card_type_id

        {
          name: card_type['name'],
          color: card_type['color_attrs']['rgb'],
          invert: !!card_type['color_attrs']['invert'] # rubocop:todo Style/DoubleNegation
        }
      end
    end

    def work_by_card_type_by_day # rubocop:todo Metrics/MethodLength
      result = @work.pc_work_by_card_type_by_day.map do |day, pc_work_by_card_type|
        work = pc_work_by_card_type.map do |card_type_id, pc_work|
          {
            card_type_id: card_type_id,
            value: pc_work,
            color: get_card_type(card_type_id)['color_attrs']['rgb']
          }
        end

        work.sort! { |a, b| a[:card_type_id] <=> b[:card_type_id] }

        [day, work]
      end

      result.to_h
    end

    private

    def decorate(card)
      card_type = get_card_type(card[:card_type_id])

      card[:color] = card_type['color_attrs']['rgb']
      card[:invert] = !!card_type['color_attrs']['invert'] # rubocop:todo Style/DoubleNegation
      card[:url] = @url_builder.card_url(card[:card_id])
      card[:users] = formatted_workers(card[:work_by_user])
      card[:card_type_name] = card_type['name']
    end

    def to_list_of_lists(list, children_name, &to_parent) # rubocop:todo Metrics/MethodLength
      group = {}

      list.each  do |item|
        parent = to_parent.call(item)
        group[parent] ||= []
        group[parent] << item
      end

      group
        .to_a
        .map do |parent, children|
          parent[children_name] = children
          parent
        end
    end

    def formatted_workers(work_by_user) # rubocop:todo Metrics/AbcSize
      users = @board.collaborators

      work_by_user
        .reject { |work| work[:user_id].nil? || work[:user_id].zero? }
        .map { |work| users[work[:user_id]]['name'].split.first + " (#{format_time(work[:duration])})" }
        .join(', ')
    end

    def get_card_type(card_type_id)
      card_types = @board.card_types

      card_types[card_type_id] || {
        'name' => 'other',
        'color_attrs' => { 'rgb' => 'white', 'invert' => false }
      }
    end

    def format_time(minutes)
      hr, min = *minutes.to_i.divmod(60)

      case hr
      when 0
        "#{min}m"
      when 1..3
        "#{hr}h #{min}m"
      else
        hr += 1 if min >= 30
        "#{hr}h"
      end
    end
  end
  # rubocop:enable Style/Documentation
end

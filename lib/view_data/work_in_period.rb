module ViewData
  class WorkInPeriod

    attr_reader :period

    def initialize api, board_id, period
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
      @work.work_done_in_period.each{|card| 
        card_type = get_card_type(card[:card_type_id])

        card[:color] = card_type["color_attrs"]["rgb"]
        card[:invert] = !!card_type["color_attrs"]["invert"]
        card[:url] = @url_builder.card_url(card[:card_id])
        card[:users] = formatted_workers(card[:work_by_user])

        card
      }
      .sort{|a, b| b[:card_type_id] <=> a[:card_type_id]}
    end

    def work_by_card_types
      @work.card_types_in_order_of_work.map{|card_type_id| 
        card_type = get_card_type card_type_id

        {
          name: card_type["name"],
          color: card_type["color_attrs"]["rgb"],
          invert: !!card_type["color_attrs"]["invert"]
        }
      }
    end

    def work_by_card_type_by_day
      
      result = @work.pc_work_by_card_type_by_day.map do |day, pc_work_by_card_type|
        work = pc_work_by_card_type.map{|card_type_id, pc_work|
          {
            card_type_id: card_type_id,
            value: pc_work,
            color: get_card_type(card_type_id)["color_attrs"]["rgb"]
          }
        }
        
        work.sort!{|a, b| a[:card_type_id] <=> b[:card_type_id]}

        [day, work]
      end

      return result.to_h

    end

    private

    def formatted_workers work_by_user
      users = @board.collaborators

      work_by_user
        .select{|work| ! (work[:user_id].nil? || work[:user_id] == 0)}
        .map{|work|  users[work[:user_id]]["name"].split.first + " (#{format_time(work[:duration])})"}
        .join(', ')
    end

    def get_card_type card_type_id
      card_types = @board.card_types
      
      card_types[card_type_id] || {
        "name" => "other",
        "color_attrs" => {"rgb" => "white", "invert" => false}
      }
    end

    def format_time minutes

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
end

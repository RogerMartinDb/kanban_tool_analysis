class WorkBuilder

  attr_reader :pc_work_by_card_type_by_day, :work_done_in_period

  def initialize period, history
    @period = period
    @activities = history.activities
    @card_histories = history.card_histories

    @day_filter = ->(day) {!(day.saturday? || day.sunday?)}
    @is_active = ->(activity) {!activity.blocked && activity.stage_type == "in_progress"}

    analyize_work
  end

  def day_filter= &filter
    @day_filter = filter
  end

  def is_active= &filter
    @is_active = filter
  end

  def card_types_in_order_of_work
    card_types = Hash.new(0)

    @pc_work_by_card_type_by_day.values.each do |card_type_work|
      card_type_work.each{|card_type_id, pc_work|
        card_types[card_type_id] += pc_work
      }
    end
    
    @card_types = card_types.to_a.sort{|a, b| b[1] <=> a[1]}.map{|a| a[0]}
  end

  private

  def analyize_work
    @pc_work_by_card_type_by_day = to_percent work_by_card_by_day

    @work_done_in_period = work_done
  end

  def work_done
    @card_histories
      .values
      .select{|card_h| card_h.current_activity.stage_type == "done"}
      .select{|card_h| card_h.activities.any?(&@is_active)}
      .map do |card_h|
        {
          card_id: card_h.id,
          name: card_h.name,
          card_type_id: card_h.card_type_id,
          work_by_user: work_by_user(card_h.activities)
        } 
      end
  end

  def work_by_user activities
    user_work = Hash.new 0

    activities
      .select(&@is_active)
      .each{|activity| user_work[activity.user_id] += activity.duration_in(@period, @day_filter)}

    user_work
      .map{|user_id, duration| {user_id: user_id, duration: duration}}
      .sort{|a, b| b[:duration] <=> a[:duration]}
  end

  def to_percent by_day   
    by_day.keys.each do |day|
      total = 0
      by_day[day].each{|card_type_id, duration| total += duration}

      next if total == 0
      by_day[day].keys.each{|card_type_id| by_day[day][card_type_id] /= total}
    end

    by_day
  end

  def work_by_card_by_day
    @period.select(&@day_filter).inject({}) do |by_day, day|
      by_day[day] = Hash.new(0)

      @activities.each do |activity_start, activities|
        next if activity_start >= day + 1

        activities.select(&@is_active).each do |activity|
          by_day[day][activity.card_type_id] += activity.duration_at day
        end
      end

      by_day
    end
  end
end

class Activity
  attr_accessor :start, :finish, :user_id, :card_type_id, :card_id,
   :stage_id, :stage_type, :swimlane_id, :blocked

  # duration of activity in minutes for given date
  def duration_at date
    morning = date.to_datetime + 9/24.to_f
    evening = date.to_datetime + 18/24.to_f

    from = start || morning
    to = finish || evening

    from = morning if from.to_date < date
    to = evening if to.to_date > date

    duration = [8*60, (to - from)*24*60].min
    [duration, 0].max.to_f
  end

  def duration_in period, day_filter
    from = [period.begin, start].max.to_date
    to = [period.end, finish || period.end].min.to_date

    (from..to)
      .select(&day_filter)
      .inject(0){|sum, date| sum += duration_at(date)}
  end

  def to_json _
    { :start => @start,
      :finish => @finish,
      :user_id => @user_id,
      :card_type_id => @card_type_id,
      :card_id => @card_id,
      :stage_id => @stage_id,
      :stage_type => @stage_type,
      :swimlane_id => @swimlane_id,
      :blocked => @blocked,
    }.to_json
  end
end

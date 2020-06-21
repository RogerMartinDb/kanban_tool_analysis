class CardHistory # rubocop:todo Style/Documentation
  attr_reader :id, :name, :card_type_id, :activities, :current_activity

  def initialize(raw_card)
    @id = raw_card['id']
    @name = raw_card['name']
    @card_type_id = raw_card['card_type_id']
    @activities = []
  end

  def <<(activity)
    @activities << activity

    @current_activity = activity if activity.finish.nil?
  end

  def to_json(_)
    {
      id: id,
      name: name,
      card_type_id: card_type_id,
      activities: activities
    }.to_json
  end
end

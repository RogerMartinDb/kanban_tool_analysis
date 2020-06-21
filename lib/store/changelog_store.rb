class ChangelogStore # rubocop:todo Style/Documentation
  def initialize(board, api)
    @board = board
    @api = api
  end

  def get_range(period)
    key = "#{@board.id}_#{period.begin}_#{period.end}"
    @@cache ||= {} # rubocop:todo Style/ClassVars
    @@cache[key] ||= find_range period
  end

  private

  def find_range(period)
    result = []

    tracker = add_changelogs(result, @board.changelogs)

    while tracker[:oldest_changelog_time] > period.begin
      more = next_changelogs(tracker)
      tracker = add_changelogs(result, more)
    end

    result
  end

  def add_changelogs(logs, raw_list)
    keep = %w[id created_at changed_object_type changed_object_id what data]
    raw_list.each { |change| logs << change.filter { |k, _| keep.include?(k) } }

    tracker = {}
    tracker[:oldest_changelog_id] = raw_list.map { |change| change['id'] }.min
    tracker[:oldest_changelog_time] = raw_list.map { |change| DateTime.parse(change['created_at']) }.min
    tracker[:oldest_changelog_time] ||= DateTime.new(0)
    tracker
  end

  def next_changelogs(tracker)
    @api.changelogs @board.id, tracker[:oldest_changelog_id]
  end
end

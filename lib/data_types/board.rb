class Board # rubocop:todo Style/Documentation
  attr_reader :id, :name, :description, :raw, :tasks, :changelogs

  def initialize(raw_board)
    @raw = raw_board

    @id = @raw['id']
    @name = @raw['name']
    @description = @raw['description']
    @tasks = @raw['tasks']
    @changelogs = @raw['changelogs']
  end

  # rubocop:todo Naming/MemoizedInstanceVariableName
  def card_types # rubocop:todo Naming/MemoizedInstanceVariableName
    @ct ||= to_h_id @raw['card_types']
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  # rubocop:todo Naming/MemoizedInstanceVariableName
  def collaborators
    @c ||= to_h_id @raw['collaborators']
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  # rubocop:todo Naming/MemoizedInstanceVariableName
  def workflow_stages
    @ws ||= to_h_id @raw['workflow_stages']
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  private

  def to_h_id(array)
    array.to_h { |item| [item['id'], item] }
  end
end

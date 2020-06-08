class Board

  attr_reader :id, :name, :description, :raw, :tasks, :changelogs

  def initialize raw_board
    @raw = raw_board

    @id = @raw["id"]
    @name = @raw["name"]
    @description = @raw["description"]
    @tasks = @raw["tasks"]
    @changelogs = @raw["changelogs"]
  end

  def card_types
    @ct ||= to_h_id @raw["card_types"]
  end

  def collaborators
    @c ||= to_h_id @raw["collaborators"]
  end

  def workflow_stages
    @ws ||= to_h_id @raw["workflow_stages"]
  end

  private

  def to_h_id array
    array.to_h{|item| [item["id"], item]}
  end

end

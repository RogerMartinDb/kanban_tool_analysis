# frozen_string_literal: true

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

  def card_types
    @_card_types ||= to_h_id @raw['card_types']
  end

  def collaborators
    @_collaborators ||= to_h_id @raw['collaborators']
  end

  def workflow_stages
    @_workflow_stages ||= to_h_id @raw['workflow_stages']
  end

  private

  def to_h_id(array)
    array.to_h { |item| [item['id'], item] }
  end
end

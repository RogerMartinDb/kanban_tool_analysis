# frozen_string_literal: true

# rubocop:todo Style/Documentation
class HistoryBuilder # rubocop:todo Metrics/ClassLength
  attr_reader :activities, :card_histories, :board

  def initialize(api, board_id, period, dependencies = {}) # rubocop:todo Metrics/AbcSize
    @from = period.begin
    @to = period.end

    @board = Board.new(api.board(board_id))
    @card_store = CardStore.new(api)
    changelog_access = dependencies[:change_log_store] || ChangelogStore.new(board, api)

    @card_store.store_cards board.tasks
    @changelogs = changelog_access.get_range period

    @activities = {}
    @card_histories = {}

    map_changelogs_to_activities
  end

  def card_histories_by_stage_id # rubocop:todo Metrics/MethodLength
    by_stage_id = {}

    card_histories
      .values
      .each do |card_history|
        card_history
          .activities
          .map(&:stage_id)
          .uniq
          .each do |stage_id|
            by_stage_id[stage_id] ||= []
            by_stage_id[stage_id] << card_history
          end
      end

    by_stage_id
  end

  private

  # rubocop:todo Naming/ConstantName
  What_not_interested_in = %w[comment_added comment_deleted subtask_checked subtask_unchecked cloned task_dependency_created task_dependency_deleted].freeze
  # rubocop:enable Naming/ConstantName

  def map_changelogs_to_activities
    @deleted_cards = []
    @workflow_stages = board.workflow_stages

    starting_cardset = rollback_to_starting_cardset

    @open_activities = initial_state starting_cardset

    create_activities
  end

  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def rollback_to_starting_cardset # rubocop:todo Metrics/CyclomaticComplexity
    cardset = board.tasks
                   .map { |task| task['id'].to_i }
                   .to_set

    AppLogger.debug "initial cardset: #{cardset}"

    @changelogs.each do |change|
      next unless change['changed_object_type'] == 'Task'
      next if What_not_interested_in.include? change['what']

      change_time = DateTime.parse change['created_at']
      card_id = change['changed_object_id'].to_i

      next if @deleted_cards.include? card_id

      AppLogger.debug "reverse processing #{change['what']} for card #{card_id} done at #{change_time}"

      break if change_time < @from

      case change['what']
      when 'created', 'moved_from_board', 'restored'
        cardset.delete card_id
      when 'updated' # rubocop:todo Lint/EmptyWhen
      when 'moved' # rubocop:todo Lint/EmptyWhen
      when 'unarchived' # rubocop:todo Lint/EmptyWhen
      when 'deleted'
        @deleted_cards << card_id
      when 'moved_to_board', 'archived'
        cardset << card_id
      else raise "I don't know how to handle a #{change['what']} change #{change['id']}, #{change.to_json}"
      end
    end

    AppLogger.debug "rolled back to start cardset: #{cardset}"

    cardset
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def initial_state(cardset) # rubocop:todo Metrics/CyclomaticComplexity
    card_states = {}

    cardset.each do |card_id| # rubocop:todo Metrics/BlockLength
      AppLogger.debug "finding initial state for card #{card_id}"

      raw_card = @card_store.find_card_detail(card_id)

      if raw_card.nil?
        @deleted_cards << card_id
        next
      end

      card_state = Activity.new

      card_state.card_id = card_id
      card_state.card_type_id = raw_card['card_type_id'].to_i
      card_state.start = @from
      card_state.finish = nil
      card_state.blocked = false

      changelogs = raw_card['changelogs']

      next if changelogs.nil?

      changelogs.each do |change| # rubocop:todo Metrics/BlockLength
        next if What_not_interested_in.include? change['what']
        next if %w[moved_to_board deleted archived restored].include? change['what']

        change_time = DateTime.parse change['created_at']

        break if change_time > @from

        AppLogger.debug "forward processing change #{change['what']} at #{change_time}"

        begin
          case change['what']
          when 'created'
            card_state.start = change_time
            card_state.user_id = change['data']['assigned_user_id'] # have raised this with kanbantool - if card is created already assigned this information is not available, currently always nil
            card_state.swimlane_id = change['data']['swimlane_id']
            card_state.stage_id = change['data']['workflow_stage_id']
            card_state.stage_type = stage_type(card_state.stage_id)
          when 'moved_from_board'
            card_state.start = change_time
            card_state.swimlane_id = change['data']['to_swimlane_id']
            card_state.stage_id = change['data']['to_workflow_stage_id']
            card_state.stage_type = stage_type(card_state.stage_id)
          when 'updated'
            case change['data']['changes']
            when ['assigned_user_id']
              card_state.user_id = if card_id == 11_700_912 && change_time < Date.new(2018, 1, 1)
                                     nil
                                   else
                                     change['data']['values'][0].to_i
                                   end
              card_state.start = change_time
            when ['block_reason']
              blocked = if card_id == 11_700_912 && change_time < Date.new(2018, 1, 1)
                          false
                        else
                          !change['data']['values'][0].empty?
                        end
              card_state.blocked = blocked
              card_state.start = change_time
            when ['description'], ['name'] # don't care about these # rubocop:todo Lint/EmptyWhen
            when ['card_type_id'] # ignore for now # rubocop:todo Lint/EmptyWhen
            else AppLogger.info "I don't know how to handle an update where changes is like #{change['data']['changes']} in change #{change['id']}"
            end
          when 'moved'
            card_state.swimlane_id = change['data']['to_swimlane_id']
            card_state.stage_id = change['data']['to_workflow_stage_id']
            card_state.stage_type = stage_type(card_state.stage_id)
            card_state.start = change_time
          when 'unarchived' # ignore # rubocop:todo Lint/EmptyWhen
          else raise "I don't know how to handle a #{change['what']} change #{change['id']}, #{change.to_json}"
          end
        rescue StandardError => e
          AppLogger.error "exception processing #{change}: #{e.full_message}"
          raise
        end
      end

      AppLogger.debug "found initial state for card #{card_id}"

      card_states[card_state.card_id] = card_state
    end

    AppLogger.debug "starting card states initialized, set of ids is: #{card_states.keys}"
    card_states
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def stage_type(stage_id)
    wf = @workflow_stages[stage_id]

    if wf.nil?
      AppLogger.info "unknown workflow stage #{stage_id}, probably has been removed from board definition"
      return 'unknown'
    end

    wf['lane_type']
  end

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def create_activities # rubocop:todo Metrics/CyclomaticComplexity
    @changelogs.reverse_each do |change| # rubocop:todo Metrics/BlockLength
      next unless change['changed_object_type'] == 'Task'
      next if What_not_interested_in.include? change['what']

      card_id = change['changed_object_id'].to_i

      change_time = DateTime.parse change['created_at']

      break if change_time > @to + 1
      next if change_time < @from
      next if @deleted_cards.include? card_id

      AppLogger.debug "processing create activites: #{change['what']} for card #{card_id}"

      begin
        case change['what']
        when 'created', 'moved_from_board', 'restored'

          current_card = @card_store.find_card(card_id)

          if current_card.nil?
            @deleted_cards << card_id
            next
          end

          activity = Activity.new

          activity.start = DateTime.parse change['created_at']
          activity.user_id = change['data']['assigned_user_id'] # have raised this with kanbantool - if card is created already assigned this information is not available, currently always nil
          activity.card_type_id = current_card['card_type_id'].to_i
          activity.card_id = change['data']['task_id'].to_i
          activity.stage_id = change['data']['workflow_stage_id'].to_i
          activity.stage_type = stage_type(activity.stage_id)
          activity.swimlane_id = change['data']['swimlane_id'].to_i
          activity.blocked = false
          activity.finish = nil

          @open_activities[activity.card_id] = activity
        when 'updated'
          case change['data']['changes']
          when ['assigned_user_id']
            open_activity = @open_activities[card_id]

            activity = open_activity.clone
            activity.finish = change_time
            store_activity activity

            open_activity.user_id = change['data']['values'][0].to_i
            open_activity.start = change_time
          when ['block_reason']
            blocked = !change['data']['values'][0].empty?
            open_activity = @open_activities[card_id]

            if open_activity.blocked != blocked
              activity = open_activity.clone
              activity.finish = change_time
              store_activity activity

              open_activity.blocked = blocked
              open_activity.start = change_time
            end
          when ['description'], ['name'] # don't care about these # rubocop:todo Lint/EmptyWhen
          when ['card_type_id'] # ignore for now # rubocop:todo Lint/EmptyWhen
          else AppLogger.info "I don't know how to handle an update where changes is like #{change['data']['changes']} in change #{change['id']}"
          end
        when 'moved'
          open_activity = @open_activities[card_id]
          AppLogger.debug "no open activity for #{card_id}" if open_activity.nil?

          activity = open_activity.clone
          activity.finish = change_time
          store_activity activity

          open_activity.swimlane_id = change['data']['to_swimlane_id']
          open_activity.stage_id = change['data']['to_workflow_stage_id'].to_i
          open_activity.stage_type = stage_type(open_activity.stage_id)
          open_activity.start = change_time
        when 'deleted', 'moved_to_board'
          next if activity.nil?

          activity = @open_activities[card_id]
          activity.finish = change_time
          store_activity activity

          @open_activities.delete(card_id)

        when 'archived', 'unarchived' # no change # rubocop:todo Lint/EmptyWhen
        else raise "I don't know how to handle a #{change['what']} change #{change['id']}"
        end
      rescue StandardError => e
        AppLogger.error "problem processing change #{change}: #{e}"
        raise
      end
    end

    @open_activities.values.each do |activity|
      store_activity(activity)
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def store_activity(activity)
    start_date = activity.start.to_date
    @activities[start_date] ||= []
    @activities[start_date] << activity.freeze

    card_id = activity.card_id
    @card_histories[card_id] ||= CardHistory.new @card_store.find_card(card_id)
    @card_histories[card_id] << activity
  end
end
# rubocop:enable Style/Documentation

require_relative 'lib/app/app_base'

class KanbanToolAnalysisApp < AppBase # rubocop:todo Style/Documentation
  AppBase.set :root, File.dirname(__FILE__)
  general_configure

  before do
    return if request.path_info == '/api_access'

    @api_access = AccessSettings.new session
    redirect '/api_access', 303 unless @api_access.valid?
  end

  get '/' do
    @user = api.current_user
    erb :index
  end

  get '/api_access' do
    erb :api_access
  end

  post '/api_access' do
    @api_access = AccessSettings.new params
    @api_access.store session
    redirect to('/')
  end

  get '/period' do
    erb :period
  end

  post '/period' do
    session[:from] = params[:from]
    session[:to] = params[:to]
    redirect to('/')
  end

  get '/board/:id' do |id|
    @board = Board.new api.board(id)
    erb :board
  end

  get '/board/:id/work_in_period' do |id|
    @view_data = ViewData::WorkInPeriod.new api, id, period

    erb :work_in_period
  end

  get '/board/:id/work_in_period/board_at_day/:date' do |id, date|
    @view_data = ViewData::BoardAtDay.new api, id, Date.parse(date)

    erb :board_at_day
  end

  get '/raw/user' do
    api.current_user.to_json
  end

  get '/raw/board/:id' do |id|
    Board.new(api.board(id)).raw.to_json
  end

  get '/raw/board/:id/activities' do |id|
    history = HistoryBuilder.new api, id, period
    history.activities.to_json
  end

  get '/raw/board/:id/card_histories' do |id|
    history = HistoryBuilder.new api, id, period
    history.card_histories.to_json
  end

  get '/raw/board/:id/changelogs' do |id|
    board = Board.new api.board(id)
    cls = ChangelogStore.new board, api

    cls.get_range(period).to_json
  end

  get '/raw/card/:id' do |id|
    api.card_detail(id).to_json
  end

  get '/debug' do
    @user = api.current_user
    erb :debug
  end

  post '/log_level' do
    level = params['level']
    logger.level = level
    erb "log level is now #{level}"
  end

  private

  def period
    from = get_date :from, Date.today - 14
    to = get_date :to, Date.today
    from..to
  end

  def get_date(param, default)
    value = session[param]
    return default if value.nil?

    Date.parse value
  end

  def api
    KbtApi.new(@api_access.domain, @api_access.api_token)
  end
end

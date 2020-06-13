require 'net/http'
require 'json'

class KbtApi

  def initialize domain, api_token
    @domain = domain
    @api_token = api_token
  end

  def board_url board_id
    "https://#{@domain}/b/#{board_id}"
  end

  def card_url board_id, card_id
    board_url(board_id) + "##{card_id}"
  end

  def current_user
    get 'users/current.json'
  end

  def board id
    get "boards/#{id}.json"
  end

  def changelogs id, before
    get "boards/#{id}/changelog.json", before: before, limit: 1000
  end

  def card card_id
    get "tasks/#{card_id}/preload.json" 
  end

  def card_detail card_id
    begin
      get "tasks/#{card_id}.json" 
    rescue RestClient::NotFound
      nil
    end
  end

  private

  def get (resource, params = nil)
    url = "https://#{@domain}/api/v3/#{resource}"

    AppLogger.debug "api call: #{url}"

    response = RestClient.get(url, params: params, Authorization:  "Bearer #{@api_token}")

    JSON.parse(response.body)
  end

end

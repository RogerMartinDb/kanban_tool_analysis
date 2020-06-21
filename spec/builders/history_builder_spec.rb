require 'spec_helper'

RSpec.describe HistoryBuilder do
  class FileFixture
    def self.as_json file_name
      JSON.parse(read(file_name))
    end

    def self.read file_name
      File.read("spec/fixtures/#{file_name}")
    end
  end

  class MockKbtApi
    def board board_id
      FileFixture.as_json("sample_board.json")
    end

    def card_detail card_id
      FileFixture.as_json("sample_card_detail_#{card_id}.json")
    end
  end

  it "generates good sample activites and card histories" do
    api = MockKbtApi.new
    board_id = 1
    period = Date.new(2020,6,1)..Date.new(2020,6,14)

    change_log_store = instance_double("ChangeLogStore", :get_range => FileFixture.as_json("sample_changelogs.json"))

    sut = HistoryBuilder.new api, board_id, period, change_log_store: change_log_store

    activities = sut.activities
    card_histories = sut.card_histories

    expect(activities.to_json).to eq FileFixture.read("sample_activities.json")
    expect(card_histories.to_json).to eq FileFixture.read("sample_card_histories.json")
  end
end
  
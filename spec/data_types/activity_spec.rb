require 'spec_helper'
require 'date'

RSpec.describe Activity, '#duration_at' do # rubocop:todo Metrics/BlockLength
  context 'time boundry of activity is known' do
    it '90 minute activity' do
      subject.start = DateTime.new(2001, 2, 3, 14, 5, 6)
      subject.finish = DateTime.new(2001, 2, 3, 15, 35, 6)
      expect(subject.duration_at(Date.new(2001, 2, 3))).to eq 90
    end

    it 'max is 8 hours in one day activity' do
      subject.start = DateTime.new(2001, 2, 3, 4, 5, 6)
      subject.finish = DateTime.new(2001, 2, 3, 23, 35, 6)
      expect(subject.duration_at(Date.new(2001, 2, 3))).to eq 8 * 60
    end
  end

  context 'near start of day' do
    it '90 minute activity' do
      subject.start = DateTime.new(2001, 2, 3, 8, 5, 0)
      subject.finish = DateTime.new(2001, 2, 3, 8, 20, 0)
      expect(subject.duration_at(Date.new(2001, 2, 3))).to eq 15
    end
  end

  context 'time boundry of activity is NOT known' do
    it 'no finish time - assume not yet finished and count to 18:00' do
      subject.start = DateTime.new(2001, 2, 3, 17, 5, 0)
      expect(subject.duration_at(Date.new(2001, 2, 3))).to eq 55
    end

    it 'no start time - assume activity started before given date and count from 09:00' do
      subject.finish = DateTime.new(2001, 2, 3, 11, 5, 0)
      expect(subject.duration_at(Date.new(2001, 2, 3))).to eq 125
    end

    it 'no known start or end time: must have been here for all given date' do
      expect(subject.duration_at(Date.new(2001, 2, 3))).to eq 8 * 60
    end
  end

  context 'not today' do
    it 'activity finished already' do
      subject.start = DateTime.new(2001, 2, 3, 8, 5, 0)
      subject.finish = DateTime.new(2001, 2, 3, 8, 20, 0)
      expect(subject.duration_at(Date.new(2001, 2, 4))).to eq 0
    end

    it 'activity not started' do
      subject.start = DateTime.new(2001, 2, 3, 8, 5, 0)
      subject.finish = DateTime.new(2001, 2, 3, 8, 20, 0)
      expect(subject.duration_at(Date.new(2001, 2, 2))).to eq 0
    end

    it "start mid-day, should be only a half day's work" do
      subject.start = DateTime.new(2020, 5, 19, 14, 32, 0)
      subject.finish = DateTime.new(2020, 5, 20, 10, 0, 0)
      expect(subject.duration_at(Date.new(2020, 5, 19))).to eq 3 * 60 + 28
    end

    it "finish mid-day, should be only a half day's work" do
      subject.start = DateTime.new(2020, 5, 19, 14, 32, 0)
      subject.finish = DateTime.new(2020, 5, 20, 13, 0, 0)
      expect(subject.duration_at(Date.new(2020, 5, 20))).to eq 4 * 60
    end
  end
end

RSpec.describe Activity, '#duration_for' do
  context 'time boundry of activity is known' do
    it 'activity fully inside period' do
      subject.start = DateTime.new(2001, 2, 3, 17, 0, 0)
      subject.finish = DateTime.new(2001, 2, 5, 15, 35, 0)

      period = Date.new(2001, 2, 1)..Date.new(2001, 2, 10)
      filter = ->(_) { true }
      expect(subject.duration_in(period, filter)).to eq 1 * 60 + 8 * 60 + 6 * 60 + 35
    end
  end
end

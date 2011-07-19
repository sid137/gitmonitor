#!/usr/bin/env ruby
require 'time-ago-in-words'
require 'observer'
require 'wrest'
require 'pp'
require './notifier'

class GitMonitor
  include Observable

  def run
    loop do
      response = "http://github.com/api/v2/json/commits/list/sid137/prizzm/master".to_uri.get.deserialise

      last_commit = response["commits"].first
      most_recent_commit = last_commit["id"]
      my_last_commit = `git --no-pager log --max-count=1 | grep "commit" | awk '{print $2}'`
      p my_last_commit
      p most_recent_commit
      if my_last_commit != most_recent_commit
        changed
        notify_observers(last_commit)
      end
      sleep(3)
    end
  end
end

class UpdateAlert

  def update commit
    person = commit["author"]["name"]
    time  = Time.parse(commit["committed_date"]).time_ago_in_words
    message = commit["message"]
    # if db schema updated, ssay so
    # if bundles updated, say so (thoguh if gaurd were ran, this wouldnt be a
    # problem)
    update = "#{person} just pushed the following commit #{time}: #{message}"
    ::Notifier.notify(update)
  end
end

gitmonitor = GitMonitor.new
gitmonitor.add_observer(UpdateAlert.new)
gitmonitor.run

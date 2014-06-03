# coding: utf-8
require File.expand_path('../boot', __FILE__)

log_dir = 'log/following'
Dir.mkdir(log_dir) unless File.directory?(log_dir)
log_error = "#{log_dir}/error.log"

begin
  myself = Twitter.user('slidebot')
  following = myself.friends_count.to_i
  following_limit = (myself.followers_count.to_i * 1.1).floor

  results = Twitter.search('speakerdeck.com')
  results.statuses.each do |s|
    break if following > following_limit
    next if s.text =~ /^RT\s/
    user = Twitter.user(s.user.screen_name)
    next unless user.lang == 'ja'
    Twitter.follow(user.id) unless user.following
    following += 1
  end
rescue => e
  File.open(log_error, 'a'){|f| f.puts Time.now; f.puts e.inspect; f.puts }
end

# coding: utf-8
require File.expand_path('../boot', __FILE__)

log_dir = 'log/following'
Dir.mkdir(log_dir) unless File.directory?(log_dir)
log_error = "#{log_dir}/error.log"

@rubytter = OAuthRubytter.new(@access_token)

begin
  myself = @rubytter.user('slidebot')
  following = myself.friends_count.to_i
  following_limit = (myself.followers_count.to_i * 1.1).floor

  results = @rubytter.search('speakerdeck.com')
  results.each do |r|
    break if following > following_limit
    next if r.text =~ /^RT\s/
    user = @rubytter.user(r.user.screen_name)
    next unless user.lang == 'ja'
    @rubytter.follow(user.id) unless user.following
    following += 1
  end
rescue => e
  File.open(log_error, 'a'){|f| f.puts Time.now; f.puts e.inspect; f.puts }
end

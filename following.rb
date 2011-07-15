# coding: utf-8
require File.expand_path('../boot', __FILE__)

log_dir = 'log/following'
Dir.mkdir(log_dir) unless File.directory?(log_dir)
log_error = "#{log_dir}/error.log"

@rubytter = OAuthRubytter.new(@access_token)

begin
	results = @rubytter.search('slidesha.re')
	results.each do |r|
		next if r.text =~ /^RT\s/
		user = @rubytter.user(r.user.screen_name)
		@rubytter.follow(user.id) unless user.following
	end
rescue => ever
	File.open(log_error, 'a') {|f| f.puts Time.now; f.puts ever; f.puts "\n"}
	exit
end

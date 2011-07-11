#require 'rubygems'
require 'bundler/setup'
Bundler.require(:default) if defined?(Bundler)

require 'time'
require 'rss'
require './lib/slideshare'
require './lib/hashtag'
require File.expand_path('../config', __FILE__)

Dir.mkdir('log') unless File.directory?('log')
File.open(LOG_LATEST, 'w') {|f| f.puts '2011-01-01'} unless File.exist?(LOG_LATEST)

@consumer = OAuth::Consumer.new(
	CONSUMER_KEY,
	CONSUMER_SECRET,
	{:site => 'http://api.twitter.com'}
)

@access_token = OAuth::AccessToken.new(
	@consumer,
	ACCESS_TOKEN,
	ACCESS_SECRET
)

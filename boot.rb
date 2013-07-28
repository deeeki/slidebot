require 'bundler/setup'
Bundler.require

Dotenv.load

$:.unshift(File.dirname(__FILE__) << '/lib')
require 'slidebot'
require 'hashtag'
require 'textfile'

Twitter.configure do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token = ENV['TWITTER_ACCESS_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_ACCESS_SECRET']
end

Dir.mkdir('log') unless File.directory?('log')
Textfile.basedir = File.expand_path('../log', __FILE__)

Hashtag.file = File.expand_path('../config/hashtag.yml', __FILE__)

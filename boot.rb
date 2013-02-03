require 'bundler/setup'
Bundler.require(:default) if defined?(Bundler)

Dotenv.load

$:.unshift(File.dirname(__FILE__) << '/lib')
require 'slidebot'
require 'hashtag'

Hashtag.file = File.expand_path('../config/hashtag.yml', __FILE__)

@consumer = OAuth::Consumer.new(
  ENV['TWITTER_CONSUMER_KEY'],
  ENV['TWITTER_CONSUMER_SECRET'],
  {:site => 'http://api.twitter.com'}
)

@access_token = OAuth::AccessToken.new(
  @consumer,
  ENV['TWITTER_ACCESS_TOKEN'],
  ENV['TWITTER_ACCESS_SECRET'],
)

Dir.mkdir('log') unless File.directory?('log')

require 'slidebot/slideshare'
require 'slidebot/slideshare/tweetable'

module Slidebot
  class << self
    attr_accessor :log, :error_log
  end
end

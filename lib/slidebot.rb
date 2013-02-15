require 'slidebot/slideshare'
require 'slidebot/speakerdeck'

module Slidebot
  class << self
    attr_accessor :log, :error_log
  end
end

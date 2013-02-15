require 'rss'
require 'slidebot/speakerdeck/slide'

module Slidebot
  module Speakerdeck
    AGENT = Mechanize.new{|a| a.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE }

    class << self
      HATEB_FEED_URL = 'http://b.hatena.ne.jp/entrylist?sort=hot&threshold=10&url=http%3A%2F%2Fspeakerdeck.com%2F&mode=rss'
      attr_reader :last_posted

      def new
        Slidebot.log = Textfile.new('sd_new.log')
        @last_posted = Time.parse(Slidebot.log.read)
        @threshold = 1
        specify_next
      end

      def hot
        Slidebot.log = Textfile.new('sd_hot.log')
        @last_posted = Time.parse(Slidebot.log.read)
        @threshold = 10
        specify_next
      end

      private
      def specify_next
        parse_hateb_feed.reverse.each do |entry|
          next if entry[:date] <= @last_posted

          begin
            @slide = Slide.new(entry[:link])
            @last_posted = entry[:date]
            break
          rescue => e
            Slidebot.error_log.append(Time.now, e.inspect, entry.inspect, '')
          end
        end
        @slide
      end

      def parse_hateb_feed
        url = "#{HATEB_FEED_URL}&threshold=#{@threshold}"
        feed = RSS::Parser.parse(url)
        feed.items.reject{|i|
          i.link.include?('?') || i.link =~ /speakerdeck.com\/(embed|player)\// ||
            !(i.link =~ /speakerdeck.com\/(u\/)?[^\/]{2,}\/(p\/)?[^\/]+$/)
        }.map{|i| { title: i.title, link: i.link, date: i.date } }
      end
    end
  end
end

require 'rss'

module Slidebot
  class << self
    attr_writer :log_file, :error_log_file

    def log
      @log ||= Log.new(@log_file) if @log_file
    end

    def error_log
      @error_log ||= Log.new(@error_log_file) if @error_log_file
    end
  end

  module Slideshare
    class << self
      HATEB_FEED_URL = 'http://b.hatena.ne.jp/entrylist?sort=hot&url=http%3A%2F%2Fwww.slideshare.net%2F&mode=rss'
      attr_reader :last_posted

      def eid
        Slidebot.log_file = File.expand_path('../../log/eid.log', __FILE__)
        @last_posted = Time.parse(Slidebot.log.read)
        @threshold = 1
        specify
      end

      def hot
        Slidebot.log_file = File.expand_path('../../log/hot.log', __FILE__)
        @last_posted = Time.parse(Slidebot.log.read)
        @threshold = 10
        specify
      end

      private
      def specify
        parse_feed.reverse.each do |entry|
          next if entry[:date] <= @last_posted

          begin
            @slide = ::Slideshare.get_slideshow(:slideshow_url => entry[:link], :detailed => 1).slideshow
            @last_posted = entry[:date]
            break
          rescue => e
            Slidebot.error_log.append("#{e.inspect}\n#{entry.inspect}\n")
            exit if e.message == 'Account Exceeded Daily Limit'
          end
        end
        @slide
      end

      def parse_feed
        url = "#{HATEB_FEED_URL}&threshold=#{@threshold}"
        feed = RSS::Parser.parse(url)
        feed.items.reject{|i| i.link.include?('?') }.map{|i| { title: i.title, link: i.link, date: i.date } }
      end
    end

    module Tweetable
      def to_status prefix = nil
        if prefix
          prefix = "*#{prefix.to_s.capitalize}!*"
        else
          prefix = (Time.parse(created) > (Time.now - 604800)) ? '*New!* ' : ''
        end
        uploaded = Time.parse(created).strftime('%Y-%m-%d')
        dl = download == '1' ? '[DL:OK]' : '[DL:NG]'
        hashtag = ::Hashtag.detect_array(tags.tag) if tags.is_a?(Hash)
        hashtag ||= ::Hashtag.detect(title)
        # https url is counted as 23 on Twitter
        title_max_length = 140 - (prefix + username + uploaded + language + dl + hashtag.to_s).size - 12 - 23
        disp_title = title
        disp_title = title[0, title_max_length - 4] + ' ...' if title.size > title_max_length
        "#{prefix}#{disp_title} #{url} (by #{username} #{uploaded}) [#{language}]#{dl} #{hashtag}"
      end
    end
  end

  class Log
    def initialize file
      @file = file
    end

    def read
      IO.read(@file)
    end

    def write str
      IO.write(@file, str, mode: 'w')
    end

    def append str
      IO.write(@file, "#{Time.now}\n#{str}\n", mode: 'a')
    end
  end
end

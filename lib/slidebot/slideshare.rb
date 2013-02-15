require 'rss'
require 'slidebot/slideshare/tweetable'

module Slidebot
  module Slideshare
    class << self
      HATEB_FEED_URL = 'http://b.hatena.ne.jp/entrylist?sort=hot&url=http%3A%2F%2Fwww.slideshare.net%2F&mode=rss'
      attr_reader :last_posted

      def new
        Slidebot.log = Textfile.new('new.log')
        @last_posted = Time.parse(Slidebot.log.read)
        @threshold = 1
        specify_next
      end

      def hot
        Slidebot.log = Textfile.new('hot.log')
        @last_posted = Time.parse(Slidebot.log.read)
        @threshold = 10
        specify_next
      end

      def popular
        targets = Hashtag.list.shuffle.map{|ht| ht.gsub(/\d/, '') }
        until targets.empty?
          target = targets.pop
          Slidebot.log = Textfile.new("popular/#{target}.log")
          posted_ids = Slidebot.log.read.split("\n")
          slides = search({ q: target, page: posted_ids.size % 12 + 1 })
          break unless slides.empty?
        end
        return nil unless slides
        slides.reject{|s| posted_ids.include?(s.id) }.first
      end

      private
      def specify_next
        parse_hateb_feed.reverse.each do |entry|
          next if entry[:date] <= @last_posted

          begin
            @slide = ::Slideshare.get_slideshow(:slideshow_url => entry[:link], :detailed => 1).slideshow
            @last_posted = entry[:date]
            break
          rescue => e
            Slidebot.error_log.append(Time.now, e.inspect, entry.inspect, '')
            exit if e.message == 'Account Exceeded Daily Limit'
          end
        end
        @slide
      end

      def parse_hateb_feed
        url = "#{HATEB_FEED_URL}&threshold=#{@threshold}"
        feed = RSS::Parser.parse(url)
        feed.items.reject{|i| i.link.include?('?') }.map{|i| { title: i.title, link: i.link, date: i.date } }
      end

      def search params = {}
        slides = []
        result = ::Slideshare.search_slideshows({
          sort: 'mostviewed',
          lang: 'ja',
          detailed: 1,
          page: 1,
        }.merge(params))
        if result.slideshows.meta.total_results.to_i.zero?
          Slidebot.error_log.append(Time.now, 'Result Nothing', result.slideshows.meta, '')
        else
          slides << result.slideshows.slideshow
        end
        slides.flatten.compact
      end
    end
  end
end

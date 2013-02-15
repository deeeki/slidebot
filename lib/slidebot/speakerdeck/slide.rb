module Slidebot
  module Speakerdeck
    class Slide
      attr_reader :url

      def initialize url
        raise 'not slide' unless url =~ /speakerdeck.com\/(u\/)?[^\/]{2,}\/(p\/)?[^\/]+$/
        raise 'not slide' if url =~ /speakerdeck.com\/embed\//
        @url = url
      end

      def html
        @html ||= AGENT.get(@url)
      end

      def title
        @title ||= html.title.sub(' // Speaker Deck', '')
      end

      def to_status prefix = nil
        prefix = prefix ? "*#{prefix.to_s.capitalize}!* " : ''
        presenter = " (by #{html.at('.presenter > h2 > a').text.strip})" rescue ''
        category = " [#{html.at('.category > a').text.strip}]" rescue ''
        hashtag = ::Hashtag.detect(title)
        # https url is counted as 23 on Twitter
        max_len = 140 - (prefix + presenter + category + hashtag.to_s).size - 2 - 23
        disp_title = title.size > max_len ? "#{htitle[0, title_max_length - 4]} ..."  : title
        "#{prefix}#{disp_title} #{url}#{presenter}#{category} #{hashtag}"
      end
    end
  end
end

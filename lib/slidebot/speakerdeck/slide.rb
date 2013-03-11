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
        @title ||= html.at('#talk-details h1').text.strip rescue nil
      end

      def presenter
        @presenter ||= html.at('#talk-details h2 a').text.strip rescue nil
      end

      def published
        @published ||= Date.parse(html.at('#talk-details mark:first-child').text.strip) rescue nil
      end

      def category
        @category ||= html.at('#talk-details mark:last-child').text.strip rescue nil
      end

      def to_status prefix = nil
        prefix = prefix ? "*#{prefix.to_s.capitalize}!* " : ''
        info = ''
        info = "by #{presenter} " if presenter
        info = (published) ? " (#{info}#{published.strftime('%Y-%m-%d')})" : " (#{info})"
        info = "#{info} [#{category}]" if category
        hashtag = ::Hashtag.detect(title)
        # https url is counted as 23 on Twitter
        max_len = 140 - (prefix + info + hashtag.to_s).size - 2 - 23
        disp_title = title.size > max_len ? "#{htitle[0, title_max_length - 4]} ..."  : title
        "#{prefix}#{disp_title} #{url}#{info} #{hashtag}"
      end
    end
  end
end

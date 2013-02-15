module Slidebot
  module Slideshare
    module Tweetable
      def to_status prefix = nil
        if prefix == :new
          prefix = (Time.parse(created) > (Time.now - 604800)) ? '*New!* ' : ''
        elsif prefix
          prefix = "*#{prefix.to_s.capitalize}!* "
        end
        uploaded = Time.parse(created).strftime('%Y-%m-%d')
        dl = download == '1' ? '[DL:OK]' : '[DL:NG]'
        hashtag = ::Hashtag.detect_array(tags.tag) if tags.is_a?(Hash)
        hashtag ||= ::Hashtag.detect(title)
        # https url is counted as 23 on Twitter
        title_max_length = 140 - (prefix.to_s + username + uploaded + language + dl + hashtag.to_s).size - 12 - 23
        disp_title = title
        disp_title = title[0, title_max_length - 4] + ' ...' if title.size > title_max_length
        "#{prefix}#{disp_title} #{url} (by #{username} #{uploaded}) [#{language}]#{dl} #{hashtag}"
      end
    end
  end
end

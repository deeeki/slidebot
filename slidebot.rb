# coding: utf-8
require File.expand_path('../boot', __FILE__)

latest_posted = Time.parse(IO.read(LOG_LATEST))
@slideshare = SlideShare.new(SLIDESHARE_API_KEY, SLIDESHARE_SECRET_KEY)
@rubytter = OAuthRubytter.new(@access_token)
@hashtag = Hashtag.new(HASHTAG_LIST)

#check hatena::bookmark entrylist
rss = RSS::Parser.parse(RSS_URL)
entries = []
rss.items.each do |i|
	entries << {
		:title => i.title,
		:link => i.link,
		:date => i.date
	}
end

entries.reverse.each do |e|
	next if e[:date] <= latest_posted

	#get slide data
	begin
		slide = @slideshare.get_slideshow(:slideshow_url => e[:link], :detailed => 1).Slideshow
	rescue => ever
		File.open(LOG_ERROR, 'a') {|f| f.puts Time.now; f.puts ever; f.puts e.inspect}
		next
	end

	#create content
	new = (Time.parse(slide.Created) > (Time.now - 604800)) ? '*New!* ' : ''
	url = Bitly.shorten(slide.URL, BITLY_LOGIN, BITLY_API_KEY).url
	uploaded = Time.parse(slide.Created).strftime('%Y-%m-%d')
	dl = slide.Download == '1' ? '[DL:OK]' : '[DL:NG]'
	hashtag = @hashtag.detect_array(slide.Tags.Tag) unless slide.Tags.blank?
	hashtag ||= @hashtag.detect(slide.Title)
	content = "#{new}#{slide.Title} #{url} (by #{slide.Username} #{uploaded}) [#{slide.Language}]#{dl} #{hashtag}"

	#post twitter
	begin
		#@rubytter.update(content)
		p content
	rescue => ever
		File.open(LOG_ERROR, 'a') {|f| f.puts Time.now; f.puts ever; f.puts e.inspect}
		break
	end
	latest_posted = e[:date]
end
#update log
File.open(LOG_LATEST, 'w') {|f| f.puts latest_posted}

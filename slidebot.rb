# coding: utf-8
require File.expand_path('../boot', __FILE__)

if (Time.now.hour % 12).zero?
	mode = 'hot'
	log_file = LOG_HOT
	rss_url = HATEB_HOT_RSS
else
	mode = 'eid'
	log_file = LOG_EID
	rss_url = HATEB_EID_RSS
end

@slideshare = SlideShare.new(SLIDESHARE_API_KEY, SLIDESHARE_SECRET_KEY)
@rubytter = OAuthRubytter.new(@access_token)
@hashtag = Hashtag.new(HASHTAG_LIST)

File.open(log_file, 'w') {|f| f.puts '2011-01-01'} unless File.exist?(log_file)
last_posted = Time.parse(IO.read(log_file))

#check hatena::bookmark entrylist
rss = RSS::Parser.parse(rss_url)
unless rss
	File.open(LOG_ERROR, 'a') {|f| f.puts "\n" + Time.now.to_s; f.puts 'RSS parse error'; f.puts rss.inspect}
	exit
end

entries = []
rss.items.each do |i|
	entries << {
		:title => i.title,
		:link => i.link,
		:date => i.date
	}
end

entries.reverse.each do |e|
	next if e[:date] <= last_posted

	#get slide data
	begin
		slide = @slideshare.get_slideshow(:slideshow_url => e[:link], :detailed => 1).Slideshow
	rescue => ever
		File.open(LOG_ERROR, 'a') {|f| f.puts "\n" + Time.now.to_s; f.puts ever; f.puts e.inspect}
		next
	end

	#create tweet
	if mode == 'hot'
		prefix = '*Hot!* '
	else
		prefix = (Time.parse(slide.Created) > (Time.now - 604800)) ? '*New!* ' : ''
	end
	url = Bitly.shorten(slide.URL, BITLY_LOGIN, BITLY_API_KEY).url
	uploaded = Time.parse(slide.Created).strftime('%Y-%m-%d')
	dl = slide.Download == '1' ? '[DL:OK]' : '[DL:NG]'
	hashtag = @hashtag.detect_array(slide.Tags.Tag) unless slide.Tags.blank?
	hashtag ||= @hashtag.detect(slide.Title)
	tweet = "#{prefix}#{slide.Title} #{url} (by #{slide.Username} #{uploaded}) [#{slide.Language}]#{dl} #{hashtag}"

	#post tweet
	begin
		@rubytter.update(tweet)
	rescue => ever
		File.open(LOG_ERROR, 'a') {|f| f.puts "\n" + Time.now.to_s; f.puts ever; f.puts e.inspect}
		exit
	end

	last_posted = e[:date]
	break
end
#update log
File.open(log_file, 'w') {|f| f.puts last_posted}

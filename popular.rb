# coding: utf-8
require File.expand_path('../boot', __FILE__)

log_dir 'log/popular'
Dir.mkdir(log_dir) unless File.directory?(log_dir)

target = HASHTAG_LIST.sample.gsub(/\d/, '')
log_file = "#{log_dir}/#{target}.log"
FileUtils.touch(log_file) unless File.exist?(log_file)
posted_ids = logs = IO.read(log_file).split("\n")
page = posted_ids.size % 12 + 1

@slideshare = SlideShare.new(SLIDESHARE_API_KEY, SLIDESHARE_SECRET_KEY)
params = {
	:q => target,
	:sort => 'relevance', #'mostviewed' is broken.
	:lang => 'ja',
	:detailed => 1,
	:page => page,
#	:items_per_page => 50, #default is 12, max is 50
}
result = @slideshare.search_slideshows(params)
if result.Slideshows.Meta.TotalResults.to_i.zero?
	File.open("#{log_dir}/error.log", 'a') {|f|
		f.puts "\n" + Time.now.to_s
		f.puts 'Result Nothing'
		f.puts result.Slideshows.Meta.inspect
	}
	exit
end

slides = result.Slideshows.Slideshow
slides.each do |s|
	next if posted_ids.include?(s.ID)

	#create tweet
	prefix = '*Popular* '
	url = Bitly.shorten(s.URL, BITLY_LOGIN, BITLY_API_KEY).url
	uploaded = Time.parse(s.Created).strftime('%Y-%m-%d')
	dl = s.Download == '1' ? '[DL:OK]' : '[DL:NG]'
	hashtag = '#' + target
	tweet = "#{prefix}#{s.Title} #{url} (by #{s.Username} #{uploaded}) [#{s.Language}]#{dl} #{hashtag}"

	#post tweet
	begin
		@rubytter.update(tweet)
	rescue => ever
		File.open("#{log_dir}/error.log", 'a') {|f| f.puts "\n" + Time.now.to_s; f.puts ever; f.puts s.inspect}
		exit
	end

	File.open(log_file, 'a') {|f| f.puts s.ID}
	break
end

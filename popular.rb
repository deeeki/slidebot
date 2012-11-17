# coding: utf-8
require File.expand_path('../boot', __FILE__)

log_dir = 'log/popular'
Dir.mkdir(log_dir) unless File.directory?(log_dir)
log_error = "#{log_dir}/error.log"

@slideshare = SlideShare.new(SLIDESHARE_API_KEY, SLIDESHARE_SECRET_KEY)
@rubytter = OAuthRubytter.new(@access_token)

targets = HASHTAG_LIST.shuffle.map{|ht| ht.gsub(/\d/, '') }
slides = []
while slides.empty? && !targets.empty?
  target = targets.pop
  log_file = "#{log_dir}/#{target}.log"
  FileUtils.touch(log_file) unless File.exist?(log_file)
  posted_ids = logs = IO.read(log_file).split("\n")
  page = posted_ids.size % 12 + 1
  params = {
    :q => target,
    :sort => 'relevance', #'mostviewed' is broken.
    :lang => 'ja',
    :detailed => 1,
    :page => page,
    #:items_per_page => 50, #default is 12, max is 50
  }
  begin
    result = @slideshare.search_slideshows(params)
  rescue => e
    File.open(log_error, 'a'){|f| f.puts "\n" + Time.now.to_s; f.puts e; f.puts target }
    next
  end

  if result.Slideshows.Meta.TotalResults.to_i.zero?
    File.open(log_error, 'a'){|f|
      f.puts "\n" + Time.now.to_s
      f.puts 'Result Nothing'
      f.puts result.Slideshows.Meta.inspect
    }
  else
    slides = Array.wrap(result.Slideshows.Slideshow)
  end
end

slides.each do |s|
  next if posted_ids.include?(s.ID)

  #create tweet
  prefix = (s.NumViews.to_i > 10000) ? '*Popular!* ' : ''
  url = Bitly.shorten(s.URL, BITLY_LOGIN, BITLY_API_KEY).url
  uploaded = Time.parse(s.Created).strftime('%Y-%m-%d')
  dl = s.Download == '1' ? '[DL:OK]' : '[DL:NG]'
  hashtag = '#' + target
  title_max_length = 140 - (prefix + url + s.Username + uploaded + s.Language + dl + hashtag.to_s).size - 12
  title = s.Title
  title = title[0, title_max_length - 4] + ' ...' if title.size > title_max_length
  tweet = "#{prefix}#{s.Title} #{url} (by #{s.Username} #{uploaded}) [#{s.Language}]#{dl} #{hashtag}"

  #post tweet
  begin
    @rubytter.update(tweet)
  rescue => ever
    File.open(log_error, 'a') {|f| f.puts "\n" + Time.now.to_s; f.puts ever; f.puts s.inspect}
    exit
  end

  File.open(log_file, 'a') {|f| f.puts s.ID}
  break
end

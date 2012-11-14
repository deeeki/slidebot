# coding: utf-8
require File.expand_path('../boot', __FILE__)

@config ||= YAML.load_file './config/speakerdeck.yml'
if (Time.now.hour % 12).zero?
  mode = 'hot'
  log_file = @config['log']['hot']
  rss_url = @config['hateb_rss']['hot']
else
  mode = 'eid'
  log_file = @config['log']['eid']
  rss_url = @config['hateb_rss']['eid']
end
log_error = @config['log']['error']

@rubytter = OAuthRubytter.new(@access_token)
@hashtag = Hashtag.new(HASHTAG_LIST)
@agent = Mechanize.new

File.open(log_file, 'w'){|f| f.puts '2011-01-01' } unless File.exist?(log_file)
last_posted = Time.parse(IO.read(log_file))

#check hatena::bookmark entrylist
rss = RSS::Parser.parse(rss_url)
unless rss
  File.open(log_error, 'a'){|f| f.puts "\n" + Time.now.to_s; f.puts 'RSS parse error'; f.puts rss.inspect }
  exit
end

entries = []
rss.items.each do |i|
  next unless i.link =~ /speakerdeck.com\/(u\/)?[^\/]{2,}\/(p\/)?[^\/]+$/
  entries << {
    :title => i.title.sub(' // Speaker Deck', ''),
    :link => i.link,
    :date => i.date
  }
end

entries.reverse.each do |e|
  next if e[:date] <= last_posted

  #get slide data
  page = @agent.get(e[:link])
  presenter = page.at('.presenter > h2 > a').text.strip
  category = " [#{page.at('.category > a').text.strip}]" rescue ''

  #create tweet
  prefix = (mode == 'hot')? '*Hot!* ' : '*New!* '
  title = e[:title]
  title = title[0, 80] + ' ...' if title.size > 84
  url = Bitly.shorten(e[:link], BITLY_LOGIN, BITLY_API_KEY).url
  hashtag = @hashtag.detect(e[:title])
  tweet = "#{prefix}#{title} #{url} (by #{presenter})#{category} #{hashtag}"

  #post tweet
  begin
    @rubytter.update(tweet)
  rescue => e
    File.open(log_error, 'a'){|f| f.puts "\n" + Time.now.to_s; f.puts e.inspect }
    exit
  end

  last_posted = e[:date]
  break
end
#update log
File.open(log_file, 'w'){|f| f.puts last_posted }

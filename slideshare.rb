require File.expand_path('../boot', __FILE__)

['log/eid.log', 'log/hot.log', 'log/error.log'].each do |log|
  IO.write(log, '2013-01-01') unless File.exist?(log)
end

Slideshare.setup
Slidebot.error_log_file = File.expand_path('../log/error.log', __FILE__)

case Time.now.hour
when 0, 12
  mode = :hot
#when 18 #TODO
  #mode = :popular
else
  mode = :eid
end

slide = Slidebot::Slideshare.__send__(mode)
exit unless slide

slide.extend Slidebot::Slideshare::Tweetable

begin
  @rubytter = OAuthRubytter.new(@access_token)
  @rubytter.update(slide.to_status)
rescue => e
  Slidebot.error_log.append("#{e.inspect}\n#{slide.inspect}\n")
end

Slidebot.log.write(Slidebot::Slideshare.last_posted)

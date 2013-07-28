require File.expand_path('../boot', __FILE__)

['log/sd_new.log', 'log/sd_hot.log'].each do |log|
  IO.write(log, '2013-01-01') unless File.exist?(log)
end

Slidebot.error_log = Textfile.new('error.log')
case Time.now.hour
when 0, 12
  mode = :hot
else
  mode = :new
end

slide = Slidebot::Speakerdeck.__send__(mode)
exit unless slide

begin
  Twitter.update(slide.to_status(mode))
rescue => e
  Slidebot.error_log.append(Time.now, e.inspect, slide.inspect, '')
end

Slidebot.log.write(Slidebot::Speakerdeck.last_posted)

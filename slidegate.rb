require File.expand_path('../boot', __FILE__)

status = "Let's check slides on #{Date.today} http://slidegate.herokuapp.com/#{Date.today.strftime('%Y/%m/%d')}"
Twitter.update(status)

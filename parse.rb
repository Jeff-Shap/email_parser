require 'sinatra'

# class EmailParseTest < Sinatra::Base

get "/" do 
  erb :emailinput
end
  
post "/" do 
  erb :parsedemail
end


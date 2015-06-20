require 'sinatra'
require './parse.rb'



get "/" do 
  erb :emailinput
end
  
post "/" do 
  if params[:file]
    @email = ParsedEmail.new(params[:file][:tempfile])
    message = "wrong type of file"
    params[:file][:type] == "text/plain" ? (erb :parsedemail) : message
  end
end


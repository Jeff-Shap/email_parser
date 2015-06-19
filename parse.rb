require 'sinatra'


get "/" do 
  erb :emailinput
end
  
post "/" do 
  if params[:file]
    erb :parsedemail
  end
end


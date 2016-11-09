require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do 
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= [] 
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the list name is invalid
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "Please enter a valid list name between 1 and 100 characters"
  elsif session[:lists].any? {|list| list[:name] == name}
    "The new list name must be unique"
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  if error = error_for_list_name(list_name)
    session[:failure] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "This list has been created"
    redirect "/lists"
  end
end
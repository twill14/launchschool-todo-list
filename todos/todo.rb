require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do 
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true  
end

configure(:development) do 
  require_relative "database_persistance"
  also_reload "database_persistance.rb"
end

helpers do 
  def list_complete?(list)
    list[:todos_total] > 0 && list[:todos_remaining_count] == 0
  end

  def list_class(list)
     "complete" if list_complete?(list)
  end

  def sort_list(lists, &block)
    complete_lists, incomplete_lists = lists.partition {|list| list_complete?(list)}
    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition {|todo| todo[:completed]}
    incomplete_todos.each {|todo| yield todo, todos.index(todo)}
    complete_todos.each {|todo| yield todo, todos.index(todo)}
  end
end

before do
  @storage = DatabasePersistance.new(logger)
end

def load_list(id)

  list = @storage.find_list(id)
  
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
  halt
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the list name is invalid
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "Please enter a valid list name between 1 and 100 characters"
  elsif @storage.all_lists.any? {|list| list[:name] == name}
    "The new list name must be unique"
  end
end

#Return an error message if the todo name is invalid
def error_for_todo(todo)
  if !(1..100).cover? todo.size
    "Please enter a valid todo name between 1 and 100 characters"
  end
end

def create_list_ids(lists)
  max = lists.map {|list| list[:id]}.max || 0
  max + 1
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:failure] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = "This list has been created"
    redirect "/lists"
  end
end

# Get a single todo list
get "/lists/:number" do
  @list_number = params[:number].to_i
  @list = load_list(@list_number)
  @todos = @storage.find_todos_for_list(@list_number)
  if @storage.all_lists.size < @list_number
    session[:failure] = "The list requested does not exist"
    redirect "/lists"
  end
  erb :todo, layout: :layout
end

# Edit an existing todo list
get "/list/:number/edit" do 
  number = params[:number].to_i
  @list = load_list(number)
  erb :edit, layout: :layout
end

# Update an existing Todo list
post "/lists/:number" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  number = params[:number].to_i
  @list = load_list(number)
  if error
    session[:failure] = error
    erb :edit, layout: :layout
  else
    @storage.update_list_name(number, list_name)
    session[:success] = "This list name has been updated"
    redirect "/lists/#{number}"
  end
end

# Delete a list
post "/lists/:number/destroy" do

  number = params[:number].to_i

  @storage.delete_list(number)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted"
    redirect "/lists"
  end
end

# Create a todo
post "/lists/:number/todos" do
  todo = params[:todo].strip
  @list_number = params[:number].to_i
  @list = load_list(@list_number)
  error = error_for_todo(todo)
  if error
    session[:failure] = error
    erb :todo, layout: :layout
  else
    @storage.create_new_todo(@list_number, todo)
    session[:success] = "The todo has been added"
    redirect "/lists/#{@list_number}"
  end
end


# Delete Todo
post "/lists/:number/todos/:index/destroy" do
   number = params[:number].to_i
   todo_id = params[:index].to_i
   @list = load_list(number)

   @storage.delete_todo_from_list(number, todo_id)
  
   if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
     status 204
   else
     session[:success] = "The todo has been deleted"
     redirect "/lists/#{number}"
   end
end

#Update a Todo
post "/lists/:number/todos/:index" do
   @list_number = params[:number].to_i
   @list = load_list(@list_number)
   todo_id = params[:index].to_i

   is_completed = params[:completed] == "true" 

   @storage.update_todo_status(@list_number, todo_id, is_completed)
   
   session[:success] = "The todo has been updated"
   redirect "/lists/#{@list_number}"
end

#Mark all todos as complete
post "/lists/:number/all-complete" do
  @list_number = params[:number].to_i
  @list = load_list(@list_number)

  @storage.mark_all_todos_as_completed(@list_number)
  
  session[:success] = "All todos complete!"
  redirect "/lists/#{@list_number}"
end

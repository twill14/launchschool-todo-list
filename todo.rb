require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do 
  enable :sessions
  set :session_secret, 'secret'
end

helpers do 
  def list_complete?(list)
    todos_count(list) > 0 && remaining_todos_count(list) == 0
  end

  def list_class(list)
     "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def remaining_todos_count(list)
    list[:todos].select {|todo| !todo[:completed]}.size
  end

  def sort_list(lists, &block)
    complete_lists, incomplete_lists = lists.partition {|list| list_complete?(list)}

    incomplete_lists.each {|list| yield list, lists.index(list)}
    complete_lists.each {|list| yield list, lists.index(list)}
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition {|todo| todo[:completed]}

    incomplete_todos.each {|todo| yield todo, todos.index(todo)}
    complete_todos.each {|todo| yield todo, todos.index(todo)}
  end
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

#Return an error message if the todo name is invalid
def error_for_todo(todo)
  if !(1..100).cover? todo.size
    "Please enter a valid todo name between 1 and 100 characters"
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:failure] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "This list has been created"
    redirect "/lists"
  end
end

# Get a single todo list
get "/lists/:number" do
  @list_number = params[:number].to_i
  @list = session[:lists][@list_number]
  erb :todo, layout: :layout
end

# Edit an existing todo list
get "/list/:number/edit" do 
  number = params[:number].to_i
  @list = session[:lists][number]
  erb :edit, layout: :layout
end

# Update an existing Todo list
post "/lists/:number" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  number = params[:number].to_i
  @list = session[:lists][number]
  if error
    session[:failure] = error
    erb :edit, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "This list name has been updated"
    redirect "/lists/#{number}"
  end
end



# Delete a list
post "/lists/:number/destroy" do
  number = params[:number].to_i
  session[:lists].delete_at(number)
  session[:success] = "The list has been deleted"
  redirect "/lists"
end

# Create a todo
post "/lists/:number/todos" do
  todo = params[:todo].strip
  @list_number = params[:number].to_i
  @list = session[:lists][@list_number]
  error = error_for_todo(todo)
  if error
    session[:failure] = error
    erb :todo, layout: :layout
  else
    @list[:todos] << {name: params[:todo], completed: false}
    session[:success] = "The todo has been added"
    redirect "/lists/#{@list_number}"
  end
end


# Delete Todo
post "/lists/:number/todos/:index/destroy" do
   number = params[:number].to_i
   todo_index = params[:index].to_i
   @list = session[:lists][number][:todos]
   @list.delete_at(todo_index)
   session[:success] = "The todo has been deleted"
   redirect "/lists/#{number}"
end

post "/lists/:number/todos/:index" do
   @list_number = params[:number].to_i
   @list = session[:lists][@list_number]
   todo_index = params[:index].to_i

   is_completed = params[:completed] == "true" 

   @list[:todos][todo_index][:completed] = is_completed
   session[:success] = "The todo has been updated"
   redirect "/lists/#{@list_number}"
end

post "/lists/:number/all-complete" do
  @list_number = params[:number].to_i
  @list = session[:lists][@list_number]
  @list[:todos].each do |todo|  
    todo[:completed] = true
  end
  
  session[:success] = "All todos complete!"
  redirect "/lists/#{@list_number}"
end

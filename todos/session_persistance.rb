class SessionPersistance
  
  def initialize(session)
     @session = session
     session[:lists] ||= []  
  end
  
  def find_list(id)
    @session[:lists].find{ |list| list[:id] == id }
  end

  def all_lists
    @session[:lists]
  end

  def create_new_list(list_name)
    id = create_list_ids(@session[:lists])
    @session[:lists] << { id: id, name: list_name, todos: []}
  end

  def delete_list(number)
    @session[:lists].reject! { |list| list[:id] == number }
  end

  def update_list_name(id, list_name)
    list = find_list(id)
    list[:name] = list_name
  end

  def create_new_todo(list_id, text)
    list = find_list(list_id)
    id = next_todo_id(list[:todos])
    list[:todos] << { id: id, name: text, completed: false}
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! {|todo| todo[:id] == todo_id}
  end

  def update_todo_status(list_id, todo_id, new_status)
    list = find_list(list_id)
    todo = list[:todos].find { |t| t[:id] == todo_id }
   todo[:completed] = new_status
  end

  def mark_all_todos_as_completed(list_id)
    list = find_list(list_id)
    list[:todos].each do |todo|  
      todo[:completed] = true
    end
  end

  private 

  def next_todo_id(todos)
    max = todos.map {|todo| todo[:id]}.max || 0
    max + 1
  end 

end
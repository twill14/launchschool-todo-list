require "sequel"

class SequelPersistance
  
  def initialize(logger)
    @db = Sequel.connect("postgres://localhost/todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
  
  def find_list(id)
    @db[:lists].left_join(:todos, list_id: :id).
    select_all(:lists).
    select_append do 
    end
     sql = <<-sql
      SELECT lists.*, 
      count(todos.id) as todos_total, 
      count(nullif(todos.completed, true)) as todos_remaining_count
      from lists 
      left join todos on todos.list_id = lists.id
      where lists.id = $1
      group by lists.id
      order by lists.name;
    sql

    result = query(sql, id)
    tuple_list_to_hash(result.first)

  end

  def all_lists
    sql = <<-sql
      SELECT lists.*, 
      count(todos.id) as todos_total, 
      count(nullif(todos.completed, true)) as todos_remaining_count
      from lists 
      left join todos on todos.list_id = lists.id
      group by lists.id
      order by lists.name;
    sql

    result = query(sql)
    
    result.map do |tuple|
        tuple_list_to_hash(tuple)
    end
  end

  def create_new_list(list_name)
    sql = "insert into lists (name) values ($1)"
    query(sql, list_name)
  end

  def delete_list(number)
    query("delete from todos where list_id = $1", number)
    query("delete from lists where id = $1", number)
  end

  def update_list_name(id, list_name)
    sql = "update lists set name = $1 where id = $2"
    query(sql, list_name, id)
  end

  def create_new_todo(list_id, text)
    sql = "insert into todos (name, list_id) values ($1, $2)"
    query(sql, text, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "delete from todos where id = $1 and list_id = $2"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
   sql = "update todos set completed = $1 where id = $2 and list_id = $3"
   query(sql, new_status, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "update todos set completed = true where list_id = $1"
    query(sql, list_id)
  end

  def find_todos_for_list(list_id)
      todo_sql = "select * from todos where list_id = $1"
      todos_result = query(todo_sql, list_id)

      todo = todos_result.map do |todo_tuple|
        { id: todo_tuple["id"].to_i, 
          name: todo_tuple["name"], 
          completed: todo_tuple["completed"] == "t" }
      end
  end

  private

  def tuple_list_to_hash(tuple)
      { id: tuple["id"].to_i, 
        name: tuple["name"], 
        todos_total: tuple["todos_total"].to_i,
        todos_remaining_count: tuple["todos_remaining_count"].to_i,
      }
  end
end
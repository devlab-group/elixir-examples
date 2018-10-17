defmodule MyMnesia.App1 do
  use Application
  alias :mnesia, as: Mnesia

  def start(_type, _args) do

    children = [
      {Task, fn ->
        # Create DB FS structure
        Mnesia.create_schema [node()]

        # Start db
        Mnesia.start

        # Create table
        case Mnesia.create_table(Person, [attributes: [
          :id, :name, :job,
        ]]) do
          {:atomic, :ok} -> IO.puts "Created"
          {:aborted, {:already_exists, name}} -> IO.puts "Table exists #{name}"
          {:aborted, reason} ->
              IO.puts "Error"
              IO.inspect reason
        end

        IO.inspect is_atom(Person)

        # # Create table
        # case Mnesia.create_table(Code.eval_string("Table"), [attributes: [
        #   :id, :name, :job,
        # ]]) do
        #   {:atomic, :ok} -> IO.puts "Created"
        #   {:aborted, {:already_exists, name}} -> IO.puts "Table exists #{name}"
        #   {:aborted, reason} ->
        #       IO.puts "Error"
        #       IO.inspect reason
        # end

        # Batch write in the table
        case Mnesia.transaction(fn ->
          Mnesia.write {Person, 1, "Admin", "administrator"}
          Mnesia.write {Person, 2, "Moderator", "moderator"}
          Mnesia.write {Person, 3, "User", "user"}
        end) do
          {:atomic, :ok} -> IO.puts "User added"
          {:aborted, reason} ->
              IO.puts "Error"
              IO.inspect reason
        end

        # Get item from the table by key
        case Mnesia.transaction(fn ->
          Mnesia.read {Person, 1}
        end) do
          {:atomic, users} -> IO.inspect users
          {:aborted, reason} ->
              IO.puts "Error"
              IO.inspect reason
        end

        # Search Person in the table where id greater than `1`
        case Mnesia.transaction(fn ->
          Mnesia.select Person, [{
            {Person, :"$1", :"$2", :"$3"},
            [{:>, :"$1", 1}],
            # [[:"$1", :"$2"]],
            [:"$$"],
          }]
        end) do
          {:atomic, users} -> IO.inspect users
          {:aborted, reason} ->
              IO.puts "Error"
              IO.inspect reason
        end

        # Get persons from the table to delete
        {:atomic, [user]} = Mnesia.transaction fn ->
          Mnesia.read {Person, 1}
        end

        IO.puts "USER SEARCH RESULT"
        IO.inspect(user)

        # user = Enum.at(users, 0)
        id = elem(user, 1)

        IO.puts "users.id"
        IO.inspect id

        # Delete item from table
        {:atomic, _} = Mnesia.transaction fn ->
          Mnesia.delete {Person, id}
        end

        # Ensure person#1 was deleted from the table
        {:atomic, users} = Mnesia.transaction fn ->
          Mnesia.select Person, [{
            {Person, :"$1", :"$2", :"$3"},
            [],
            [:"$$"],
          }], 1, :read
        end

        IO.inspect users
        IO.puts "DONE"

        Mnesia.stop
      end}
    ]

    opts = [strategy: :one_for_one, name: KVServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

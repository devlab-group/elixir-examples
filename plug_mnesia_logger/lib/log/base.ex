defmodule Log.Base do
  alias :mnesia, as: Mnesia

  # defstruct [:name, :id, :create_date]

  @table_prefix "Log"

  @table_opts [attributes: [
      :id, :level, :message, :time
    ],
    # type: :ordered_set,
    disc_copies: [node()],
    storage_properties: [
      [dets: [auto_save: 1000]],
    ],
  ]

  @table_limit 4_000
  @table_size 4 * 1024 * 1024 * 1024

  def init do
    result = Mnesia.create_table __MODULE__, [
      attributes: [
        :id, :name, :create_date,
      ],
      # type: :ordered_set,
      disc_copies: [node()],
      storage_properties: [
        [dets: [auto_save: 1000]],
      ]
    ]

    case result do
      {:atomic, :ok} -> Mnesia.wait_for_tables([__MODULE__], 1000); {:ok}
      {:aborted, {:already_exists, _}} -> {:ok}
    end
  end

  def drop do
    Mnesia.clear_table(__MODULE__)
  end

  def dump do
    Mnesia.dump_tables([__MODULE__])
  end

  def list do
    {:atomic, tables} = Mnesia.transaction fn ->
      Mnesia.select __MODULE__, [
        {
          {__MODULE__, :"$1", :"$2", :"$3"},
          [],
          [:"$$"],
        },
      ]
    end

    {:ok, tables}
  end

  def find_log(name) do
    {:atomic, tables} = Mnesia.transaction fn ->
      Mnesia.select __MODULE__, [
        {
          {__MODULE__, :"$1", :"$2", :"$3"},
          [{:==, :"$2", name}],
          [:"$$"],
        },
      ]
    end

    if length(tables) > 0 do
      tables = tables
      |> Enum.map(fn (item) ->
          enum_to_log(item)
        end)
      |> Enum.sort(fn a, b ->
          a[:id] <= b[:id]
        end)

      {:ok, Enum.at(tables, 0)}
    else
      {:ok, nil}
    end
  end

  def get_log(name) do
    case find_log(name) do
      {:ok, nil} -> {:error, {:not_found, name}}
      result -> result
    end
  end

  def create_log(name) do
    count = count_tables()

    if count >= @table_limit do
      {:error, {:table_limit, @table_limit}}
    end

    result = case get_last_table() do
      {:ok, nil} -> create_log_table(name, 1)
      {:ok, table} -> create_log_table(name, table[:id] + 1)
    end

    result
  end

  def log_size(log) do
    atom = id_to_name log[:id]
    size = Mnesia.table_info(atom, :memory)
    size * :erlang.system_info(:wordsize)
  end

  def get_active_log(name) do
    case find_log(name) do
      {:ok, nil} -> create_log(name)
      {:ok, log} -> if (log_size(log) > @table_size) do
        create_log(name)
      else
        {:ok, log}
      end
      other -> other
    end
  end

  defp write_data(log, {id, level, message, time}) do
    table = id_to_name log[:id]

    result = Mnesia.transaction fn ->
      Mnesia.write({
        table, id, level, message, time,
      })
    end

    case result do
      {:atomic, :ok} -> {:ok}
      {:aborted, reason} -> {:error, reason}
      x -> x
    end
  end

  def write(name, data) do
    {:ok, log} = get_active_log name
    write_data log, data
  end

  def read(name, count \\ 0) do
    {:ok, log} = get_active_log name

    table = id_to_name(log[:id])

    {:atomic, list} = Mnesia.transaction fn ->
      Mnesia.select table, [
        {
          {table, :"$1", :"$2", :"$3", :"$4"},
          [],
          [:"$$"],
        },
      ]
    end

    {:ok, Enum.map(list, fn item -> enum_to_log_item(item) end)}
  end

  defp get_last_table do
    {:atomic, tables} = Mnesia.transaction(fn ->
      key = Mnesia.last(__MODULE__)
      Mnesia.read({__MODULE__, key})
    end)

    if length(tables) > 0 do
      {:ok, tuple_to_log(Enum.at(tables, 0))}
    else
      {:ok, nil}
    end
  end

  defp create_log_table(name, id) do
    table = {
      __MODULE__, id, name, DateTime.utc_now
    }

    result = Mnesia.transaction fn ->
      Mnesia.write table
    end

    case result do
      {:atomic, :ok} -> case create_mnesia_table_by_id(id) do
        {:ok} -> {:ok, tuple_to_log(table)}
        result -> result
      end
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_mnesia_table_by_id(id) do
    atom = id_to_name id
    create_mnesia_table atom
  end

  # @doc """
  # Creates mnesia table with `name` and default log items attributes from
  # `@table_opts`
  # """
  @spec create_mnesia_table(atom) :: {:ok} | {:error, Error}
  defp create_mnesia_table(name) do
    case Mnesia.create_table(name, @table_opts) do
      {:aborted, {:already_exists, ^name}} -> {:ok}
      {:atomic, :ok} -> Mnesia.wait_for_tables([name], 1000); {:ok}
      {:aborted, reason} -> {:error, reason}
      result -> result
    end
  end

  def count_tables do
    Mnesia.table_info(__MODULE__, :size)
  end

  def id_to_name(id) do
    (@table_prefix <> Integer.to_string(id)) |> String.to_atom
  end

  ### Mnesia types convertion

  defp enum_to_log([id, name, create_date]) do
    %{
      id: id,
      name: name,
      create_date: create_date,
    }
  end

  defp tuple_to_log({_, id, name, create_date}) do
    %{
      id: id,
      name: name,
      create_date: create_date,
    }
  end

  def enum_to_log_item([id, level, message, create_date]) do
    %{
      id: id,
      level: level,
      message: message,
      create_date: create_date,
    }
  end

  def tuple_to_log_item({_, id, level, message, create_date}) do
    %{
      id: id,
      level: level,
      message: message,
      create_date: create_date,
    }
  end
end

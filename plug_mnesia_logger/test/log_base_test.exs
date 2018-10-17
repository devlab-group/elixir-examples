defmodule PlugLoggerTest do
  use ExUnit.Case

  setup do
    Log.Server.start_link([])
    Log.Base.drop
    %{}
  end

  test "find_log on empty log returns 'nil'" do
    {:ok, table} = Log.Server.find_log "test"

    assert table == nil
  end

  test "get_log on empty log returns '{:error}'" do
    result = Log.Base.get_log "test"

    assert result == {:error, {:not_found, "test"}}
  end

  test "create_log" do
    # Create log table
    result = Log.Base.create_log "test"

    assert elem(result, 0) == :ok

    log = elem(result, 1)

    assert log[:id] == 1
    assert log[:name] == "test"

    # Create another table with the same name
    result = Log.Base.create_log "test"

    assert elem(result, 0) == :ok

    log = elem(result, 1)

    assert log[:id] == 2
    assert log[:name] == "test"
  end

  test "log_size" do
    name = "test_size"
    {:ok, _} = Log.Base.create_log name
    {:ok, log} = Log.Base.find_log name

    size = Log.Base.log_size log

    assert is_number(size)
    assert size > 0
  end

  test "write_log" do
    name = "write_test"
    Log.Base.write(name, {
      1, "info", "This is the first log item", NaiveDateTime.utc_now
    })

    {:ok, list} = Log.Base.read(name)

    assert length(list) == 1

    log = Enum.at(list, 0)

    assert log[:id] == 1
    assert log[:level] == "info"
    assert log[:message] == "This is the first log item"
  end
end

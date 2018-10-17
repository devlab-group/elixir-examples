defmodule Log.Server do
  use GenServer

  # defstruct [:name, :id, :create_date]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  def init(state) do
    {:ok, state}
  end

  def drop do
    GenServer.cast(__MODULE__, {:drop})
  end

  def dump do
    GenServer.cast(__MODULE__, {:dump})
  end

  def find_log(name) do
    GenServer.call(__MODULE__, {:find_log, name})
  end

  def get_log(name) do
    GenServer.call(__MODULE__, {:get_log, name})
  end

  def create_log(name) do
    GenServer.call(__MODULE__, {:create_log, name})
  end

  def write(name, data) do
    GenServer.cast(__MODULE__, {:write, name, data})
  end

  def read(name) do
    GenServer.call(__MODULE__, {:read, name})
  end

  # Server

  def handle_cast({:drop}, state) do
    Log.Base.drop
    {:noreply, state}
  end

  def handle_cast({:dump}, state) do
    Log.Base.dump
    {:noreply, state}
  end

  def handle_cast({:write, name, data}, state) do
    Log.Base.write name, data
    {:noreply, state}
  end

  def handle_call({:read, name}, _from, state) do
    {:reply, Log.Base.read(name), state}
  end

  def handle_call({:find_log, name}, _from, state) do
    {:reply, Log.Base.find_log(name), state}
  end

  def handle_call({:get_log, name}, _from, state) do
    {:reply, Log.Base.get_log(name), state}
  end

  def handle_call({:create_log, name}, _from, state) do
    result = Log.Base.create_log(name)
    {:reply, result, state}
  end

  def handle_call(_message, _from, state) do
    {:reply, nil, state}
  end
end

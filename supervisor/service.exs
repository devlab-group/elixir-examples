defmodule App.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(App.Service, [])
    ]

    supervise(children, [strategy: :one_for_one])
  end
end

defmodule App.Service do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    IO.puts "OK"
    {:ok, :ok}
  end

  def check do
    GenServer.call(__MODULE__, {:check})
  end

  def pid do
    Process.whereis(__MODULE__)
  end

  def kill do
    Process.exit(pid(), :kill)
  end

  def handle_call({:check}, _from, :ok) do
    {:reply, :ok, :ok}
  end
end

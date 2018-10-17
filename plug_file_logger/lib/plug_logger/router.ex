defmodule PlugLogger.Router do
  use PlugLogger.BaseRouter

  plug Plug.Logger
  plug Plug.Parsers,
      parsers: [:json],
      json_decoder: Poison

  @doc """
  Handles log writing request. Add JSON encoded body into log file
  """
  def route(conn, "POST", [service], opts) do
    dir = Path.absname(opts[:dir])
    path = Path.join([dir, service <> ".log"])

    unless File.dir?(dir) do
      case File.mkdir(path) do
        {:ok} -> send_ok conn
        {:error, error} -> send_error conn, error
      end
    end

    log = conn.body_params

    case validateLogItem(log) do
      {:ok} ->
        # Write data into log
        File.open!(path, [:append])
        |> IO.write(Poison.encode!(log) <> "\n")
        |> File.close()
        conn |> send_ok(true)
      {:error, field} ->
        conn |> send_bad_req(%{
          error: %{
            code: "missed_field",
            message: "Field '#{field}' is missed.",
            field: field,
          },
        })
    end
  end

  @doc """
  Handles log reading request to "/%SERVICE%". Returns whole file log
  """
  def route(conn, "GET", [service], opts) do
    dir = Path.absname(opts[:dir])
    path = Path.join([dir, service <> ".log"])

    if File.exists?(path) do
      case File.read(path) do
        {:ok, content} -> send_ok conn, content
        {:error, error} -> send_error conn, error
      end
    else
      send_not_found conn
    end
  end

  def route(conn, _method, _path, _opts) do
    send_not_found conn
  end

  ## Custom methods
  def validateLogItem(log) do
    cond do
      not Map.has_key?(log, "level") -> {:error, "level"}
      not Map.has_key?(log, "time") -> {:error, "time"}
      not Map.has_key?(log, "message") -> {:error, "message"}
      true -> {:ok}
    end
  end

  # Send JSON encoded response

  def send_responce(conn, code, message) when is_binary(message) == false do
    send_responce conn, code, Poison.encode!(message)
  end
end

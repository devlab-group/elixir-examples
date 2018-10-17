defmodule PlugLogger.Router do
  use PlugLogger.BaseRouter

  plug Plug.Logger
  plug Plug.Parsers,
      parsers: [:json],
      json_decoder: Poison

  @doc """
  Handles log writing request. Add JSON encoded body into log file
  """
  def route(conn, "POST", [service, "messages"], _opts) do
    log = conn.body_params

    case validatelogItem(log) do
      {:ok} ->
        # Write data into log
        {:ok, time, _} = DateTime.from_iso8601(log["time"])
        Log.Server.write(service, {
          UUID.uuid4(), log["level"], log["message"], time,
        })
        send_ok conn, true
      {:error, field} ->
        send_bad_req conn, %{
          error: %{
            code: "missed_field",
            message: "Field '#{field}' is missed.",
            field: field,
          },
        }
    end
  end

  def route(conn, "POST", [service], _opts) do
    case Log.Server.find_log(service) do
      {:ok, nil} -> case Log.Server.create_log(service) do
        {:ok, table} -> send_ok conn, table
        {:error, error} -> send_error conn, error
      end
      {:ok, log} -> send_conflict conn
      {:error, error} -> send_error conn, error
    end
  end

  def route(conn, "DELETE", [service], _opts) do
    Log.Server.drop

    send_ok conn, true
  end

  @doc """
  Handles log reading request to "/%SERVICE%". Returns whole file log
  """
  def route(conn, "GET", [service, "messages"], opts) do
    case Log.Server.find_log(service) do
      {:ok, nil} -> send_not_found conn
      {:ok, log} -> case Log.Server.read(service) do
        {:ok, items} -> send_ok conn, items
        {:error, error} -> send_error conn, error
      end
      {:error, error} -> send_error conn, error
    end
  end

  def route(conn, _method, _path, _opts) do
    send_not_found conn
  end

  ## Custom methods

  def key_missed?(map, key) do
    Map.has_key?(map, key) == false
  end

  def validatelogItem(log) do
    cond do
      key_missed?(log, "level") -> {:error, "level"}
      key_missed?(log, "time") -> {:error, "time"}
      key_missed?(log, "message") -> {:error, "message"}
      true -> {:ok}
    end
  end

  # Send JSON encoded response

  def send_responce(conn, code, message) when is_binary(message) == false do
    send_responce conn, code, Poison.encode!(message)
  end
end

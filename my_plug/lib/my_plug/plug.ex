defmodule MyPlug.Plug do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    conn
    |> put_resp_header("content-type", "plain-text")
    |> send_resp(200, "Hello, world")
  end
end

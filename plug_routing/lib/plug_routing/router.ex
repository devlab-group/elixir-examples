defmodule PlugRouting.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    conn |> send_resp(200, "Welcome")
  end

  get "/user/:user_id" do
    conn |> send_resp(200, "User ##{conn.path_params["user_id"]}")
  end

  match _ do
    conn |> send_resp(404, "Nothing found!")
  end
end

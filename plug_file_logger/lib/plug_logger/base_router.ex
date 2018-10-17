defmodule PlugLogger.BaseRouter do
  defmacro __using__(_opts) do
    quote do
      use Plug.Builder

      def init(options) do
        options
      end

      def call(conn, opts) do
        conn
          |> super(opts) # calls Plug.Logger and Plug.Head
          |> assign(:called_all_plugs, true)
          |> resolve(opts)
      end

      def resolve(conn, opts) do
        route(conn, conn.method, conn.path_info, opts)
      end

      def send_responce(conn, code, message) when is_binary(message) do
        Plug.Conn.send_resp conn, code, message
      end

      # send not found

      def send_not_found(conn) do
        send_responce conn, 404, "Nothing found"
      end

      # send bad request

      def send_bad_req(conn) do
        send_responce conn, 400, "Bad_request"
      end

      def send_bad_req(conn, message) do
        send_responce conn, 400, message
      end

      def send_error(conn) do
        send_responce(conn, 500, "Unknown_error")
      end

      def send_error(conn, content) do
        send_responce(conn, 500, content)
      end

      # send ok

      def send_ok(conn) do
        send_responce(conn, 200, "")
      end

      def send_ok(conn, content) do
        send_responce(conn, 200, content)
      end
    end
  end
end

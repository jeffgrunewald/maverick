defmodule Maverick.Exception.Default do
  defmacro __using__(_opts) do
    quote do
      def error_code(%{error_code: error_code}) when is_integer(error_code), do: error_code
      def error_code(_), do: 500

      def message(t), do: Exception.message(t)

      def handle(t, conn) do
        status = error_code(t)

        response =
          %{
            error_code: status,
            error_message: message(t)
          }
          |> Jason.encode!()

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(status, response)
      end

      defoverridable(error_code: 1, message: 1, handle: 2)
    end
  end
end

defprotocol Maverick.Exception do
  @fallback_to_any true

  @spec error_code(t) :: 100..999
  def error_code(t)

  @spec message(t) :: String.t()
  def message(t)

  @spec handle(t, Plug.Conn.t()) :: Plug.Conn.t()
  def handle(t, conn)
end

defimpl Maverick.Exception, for: Any do
  use Maverick.Exception.Default
end

defimpl Maverick.Exception, for: Plug.Parsers.UnsupportedMediaTypeError do
  use Maverick.Exception.Default

  def error_code(_), do: 400

  def message(exception) do
    "Unsupported media type: #{exception.media_type}"
  end
end

defmodule Maverick.Api.Generator do
  @moduledoc false

  def generate_router(api) do
    case build_router_module(api) do
      :ok -> :ok
      _ -> {:error, "Failed to initialize the handler"}
    end
  end

  defp build_router_module(api) do
    contents =
      quote location: :keep do
        use Plug.Router

        require Logger

        plug(Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Jason)

        plug(:match)
        plug(:dispatch)

        unquote(generate_match_functions(api.list_routes()))

        match _ do
          response =
            %{error_code: 404, error_message: "Not Found"}
            |> Jason.encode!()

          var!(conn)
          |> put_resp_content_type("application/json", nil)
          |> send_resp(404, response)
        end
      end

    api.router()
    |> Module.create(contents, Macro.Env.location(__ENV__))
  end

  defp generate_match_functions(routes) do
    for %Maverick.Route{
          args: arg_type,
          function: function,
          method: method,
          module: module,
          raw_path: path,
          success_code: success,
          error_code: error
        } = route <-
          routes do
      method_macro = method |> String.downcase() |> String.to_atom()
      escaped_route = Macro.escape(route)

      result =
        quote location: :keep do
          unquote(method_macro)(unquote(path)) do
            var!(conn) = merge_private(var!(conn), maverick_route: unquote(escaped_route))
            apply(unquote(module), :call, [var!(conn), []])
          end
        end

      result
    end
  end

  def wrap_response(conn, {:ok, headers, response}, success, _error) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json", nil)
    |> add_headers(headers)
    |> Plug.Conn.send_resp(success, Jason.encode!(response))
  end

  def wrap_response(conn, {:error, error_message}, _success, error) do
    response =
      %{error_code: error, error_message: error_message}
      |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json", nil)
    |> Plug.Conn.send_resp(error, response)
  end

  def wrap_response(conn, response, success, _error) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json", nil)
    |> Plug.Conn.send_resp(success, Jason.encode!(response))
  end

  def decode_arg_type(conn, :conn) do
    conn
  end

  def decode_arg_type(conn, _) do
    Map.get(conn, :params)
  end

  defp add_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, conn ->
      Plug.Conn.put_resp_header(conn, key, value)
    end)
  end
end

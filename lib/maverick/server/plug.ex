defmodule Maverick.Server.Plug do
  @behaviour Maverick.Server

  def child_spec(api, opts) do
    port = Keyword.get(opts, :port, 4000)

    {Plug.Cowboy, scheme: :http, plug: api.router_module(), options: [port: port]}
  end

  def router_contents(routes) do
    IO.inspect(routes, label: "routes")

    quote location: :keep do
      use Plug.Router

      require Logger

      plug(Plug.Parsers,
        parsers: [:urlencoded, :json],
        pass: ["text/*"],
        json_decoder: Jason
      )

      plug(:match)
      plug(:dispatch)

      unquote(generate_match_functions(routes))

      match _ do
        var!(conn)
        |> send_resp(404, "Not Found")
      end
    end
  end

  defp generate_match_functions(routes) do
    for %Maverick.Route{
          args: arg_type,
          function: function,
          method: method,
          module: module,
          path: path,
          success_code: success,
          error_code: error
        } <-
          routes do
      plug_path = to_plug_path(path)
      method_macro = method |> String.downcase() |> String.to_atom()

      result =
        quote location: :keep do
          unquote(method_macro)(unquote(plug_path)) do
            arg = Maverick.Server.Plug.decode_arg_type(var!(conn), unquote(arg_type))
            response = apply(unquote(module), unquote(function), [arg])

            Maverick.Server.Plug.wrap_response(
              var!(conn),
              response,
              unquote(success),
              unquote(error)
            )
          end
        end

      IO.puts(Macro.to_string(result))

      result
    end
  end

  defp to_plug_path(path) do
    result =
      Enum.map(path, fn element ->
        case element do
          {:variable, variable} ->
            ":" <> variable

          _ ->
            element
        end
      end)
      |> Enum.join("/")

    "/" <> result
  end

  def to_request(conn) do
    %Maverick.Request{
      body: nil,
      body_params: conn.params,
      headers: conn.req_headers |> Enum.into(%{}),
      host: conn.host,
      method: conn.method |> to_string(),
      params: conn.params,
      path: conn.request_path,
      path_params: conn.path_params,
      port: conn.port,
      query_params: conn.query_params,
      raw_path: conn.request_path,
      remote_ip: conn.remote_ip,
      scheme: conn.scheme,
      socket: nil,
      version: nil
    }
  end

  def wrap_response(conn, {:ok, headers, response}, success, _error) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json", nil)
    |> add_headers(headers)
    |> Plug.Conn.send_resp(success, Jason.encode!(response))
  end

  def wrap_response(conn, response, success, _error) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json", nil)
    |> Plug.Conn.send_resp(success, Jason.encode!(response))
  end

  def decode_arg_type(conn, :request) do
    Maverick.Server.Plug.to_request(conn)
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

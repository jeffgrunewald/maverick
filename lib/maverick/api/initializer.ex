defmodule Maverick.Api.Initializer do
  @moduledoc false

  def init(api) do
    case build_router_module(api) do
      :ok -> {:ok, nil, {:continue, :exit}}
      _ -> {:error, "Failed to initialize the handler"}
    end
  end

  defp build_router_module(api) do
    contents =
      quote location: :keep do
        use Plug.Router

        require Logger

        plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["text/*"], json_decoder: Jason)

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
        } <-
          routes do
      method_macro = method |> String.downcase() |> String.to_atom()

      result =
        quote location: :keep do
          unquote(method_macro)(unquote(path)) do
            try do
              arg = Maverick.Api.Initializer.decode_arg_type(var!(conn), unquote(arg_type))
              response = apply(unquote(module), unquote(function), [arg])

              Maverick.Api.Initializer.wrap_response(
                var!(conn),
                response,
                unquote(success),
                unquote(error)
              )
            rescue
              exception ->
                %{tag: tag, handler: {mod, func, args}} = Maverick.Exception.fallback(exception)

                Logger.info(fn ->
                  "#{inspect(exception)} encountered processing request #{inspect(var!(conn))}; falling back to #{
                    tag
                  }"
                end)

                response = apply(mod, func, args)

                var!(conn)
                |> Plug.Conn.put_resp_content_type("application/json", nil)
                |> Plug.Conn.send_resp(Maverick.Exception.error_code(exception), response)
            end
          end
        end

      result
    end
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

  def decode_arg_type(conn, :request) do
    Maverick.Api.Initializer.to_request(conn)
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

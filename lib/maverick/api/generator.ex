defmodule Maverick.Api.Generator do
  @moduledoc false

  def generate_router(api) do
    build_router_module(api)
  end

  defp build_router_module(api) do
    contents =
      quote location: :keep do
        use Plug.Router

        require Logger

        plug(:match)
        plug(Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Jason)
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
          args: _arg_type,
          function: _function,
          method: method,
          module: module,
          raw_path: path,
          success_code: _success,
          error_code: _error
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

  def decode_arg_type(conn, :conn) do
    conn
  end

  def decode_arg_type(conn, _) do
    Map.get(conn, :params)
  end
end

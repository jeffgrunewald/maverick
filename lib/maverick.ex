defmodule Maverick do
  @moduledoc false

  defmacro __using__(opts) do
    scope = Keyword.get(opts, :scope, "")

    quote do
      Module.register_attribute(__MODULE__, :maverick_routes, accumulate: true)
      Module.put_attribute(__MODULE__, :maverick_route_scope, unquote(scope))

      @on_definition Maverick
      @before_compile Maverick
    end
  end

  def __on_definition__(%Macro.Env{module: module}, :def, name, args, _guards, _body) do
    route_info = Module.get_attribute(module, :route) || :no_route

    unless route_info == :no_route do
      scope = Module.get_attribute(module, :maverick_route_scope)
      path = Keyword.fetch!(route_info, :path)
      arg_type = Keyword.get(route_info, :args, :params)
      success_code = Keyword.get(route_info, :success, 200) |> parse_http_code()
      error_code = Keyword.get(route_info, :error, 404) |> parse_http_code()

      method =
        route_info
        |> Keyword.get(:method, "POST")
        |> to_string()
        |> String.upcase()

      {:ok, path, "", %{}, _, _} =
        (ensure_leading_slash(scope) <> ensure_leading_slash(path))
        |> Maverick.PathParser.parse()

      Module.put_attribute(module, :maverick_routes, %{
        module: module,
        function: name,
        arity: length(args),
        args: arg_type,
        method: method,
        path: path,
        success_code: success_code,
        error_code: error_code
      })
    end

    Module.delete_attribute(module, :route)
  end

  def __on_definition__(env, _kind, _name, _args, _guards, _body) do
    route_info = Module.get_attribute(env.module, :route) || :no_route

    unless route_info == :no_route do
      Module.delete_attribute(env.module, :route)
    end
  end

  defmacro __before_compile__(env) do
    routes = Module.get_attribute(env.module, :maverick_routes, [])
    Module.delete_attribute(env.module, :maverick_routes)

    contents =
      quote do
        def routes() do
          unquote(Macro.escape(routes))
        end
      end

    env.module
    |> Module.concat(Maverick.Router)
    |> Module.create(contents, Macro.Env.location(__ENV__))

    []
  end

  defp parse_http_code(code) when is_integer(code), do: code

  defp parse_http_code(code) when is_binary(code) do
    {code, _} = Integer.parse(code)
    code
  end

  defp ensure_leading_slash("/" <> _rest = string), do: string
  defp ensure_leading_slash(path), do: "/" <> path
end

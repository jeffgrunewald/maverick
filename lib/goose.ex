defmodule Goose do
  @moduledoc false

  defmacro __using__(opts) do
    scope = Keyword.get(opts, :scope, "") |> String.split("/")

    quote do
      Module.register_attribute(__MODULE__, :goose_routes, accumulate: true)
      Module.put_attribute(__MODULE__, :goose_route_scope, unquote(scope))

      @on_definition Goose
      @before_compile Goose
    end
  end

  def __on_definition__(%Macro.Env{module: module}, :def, name, args, _guards, _body) do
    route_info = Module.get_attribute(module, :route) || :no_route

    unless route_info == :no_route do
      scope = Module.get_attribute(module, :goose_route_scope)
      path = Keyword.fetch!(route_info, :path) |> String.split("/")

      method =
        route_info
        |> Keyword.get(:method, "POST")
        |> to_string()
        |> String.upcase()

      Module.put_attribute(module, :goose_routes, %{
        module: module,
        function: name,
        argc: length(args),
        argv: Enum.map(args, fn {name, _, _} -> to_string(name) end),
        method: method,
        path: (scope ++ path) |> Enum.filter(fn item -> item != "" end),
        opts: Keyword.get(route_info, :opts, [])
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
    routes = Module.get_attribute(env.module, :goose_routes, [])
    Module.delete_attribute(env.module, :goose_routes)

    contents =
      Enum.map(routes, fn route ->
        gen_route_function(route)
      end)

    env.module
    |> Module.concat(Goose.Routes)
    |> Module.create(contents, Macro.Env.location(__ENV__))

    []
  end

  defp gen_route_function(route) do
    quote do
      def unquote(route.function)() do
        %{
          module: unquote(route.module),
          function: unquote(route.function),
          argc: unquote(route.argc),
          argv: unquote(route.argv),
          method: unquote(route.method),
          path: unquote(route.path),
          opts: unquote(route.opts)
        }
      end
    end
  end
end

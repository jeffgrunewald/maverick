defmodule Maverick do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @type api :: module()
  @type otp_app :: atom()
  @type root_scope :: String.t()

  defmacro __using__(opts) do
    scope = Keyword.get(opts, :scope, "")

    quote location: :keep do
      use Plug.Builder

      require Logger

      Module.register_attribute(__MODULE__, :maverick_routes, accumulate: true)
      Module.put_attribute(__MODULE__, :maverick_route_scope, unquote(scope))

      @on_definition Maverick
      @before_compile Maverick

      def call(%Plug.Conn{private: %{maverick_route: route}} = conn, _opts) do
        conn = super(conn, route)
        args = Maverick.Arguments.get(route, conn)
        response = apply(__MODULE__, route.function, args)

        Maverick.handle_response(response, conn)
      end
    end
  end

  def __on_definition__(%Macro.Env{module: module}, :def, name, _args, _guards, _body) do
    route_info = Module.get_attribute(module, :route) || :no_route

    unless route_info == :no_route do
      scope = Module.get_attribute(module, :maverick_route_scope)
      path = Keyword.fetch!(route_info, :path)
      args = Keyword.get(route_info, :args, [:params]) |> Maverick.Arguments.validate()
      success_code = Keyword.get(route_info, :success, 200) |> parse_http_code()
      error_code = Keyword.get(route_info, :error, 404) |> parse_http_code()

      method =
        route_info
        |> Keyword.get(:method, "POST")
        |> to_string()
        |> String.upcase()

      raw_path =
        [scope, path]
        |> Enum.join("/")
        |> Maverick.Path.validate()

      path = Maverick.Path.parse(raw_path)

      Module.put_attribute(module, :maverick_routes, %Maverick.Route{
        module: module,
        function: name,
        args: args,
        method: method,
        path: path,
        raw_path: raw_path,
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

  def handle_response(%Plug.Conn{} = conn, _) do
    conn
  end

  def handle_response(term, conn) do
    response = Maverick.Response.handle(term, conn)
    handle_response(response, conn)
  end

  defp parse_http_code(code) when is_integer(code), do: code

  defp parse_http_code(code) when is_binary(code) do
    {code, _} = Integer.parse(code)
    code
  end
end

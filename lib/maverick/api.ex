defmodule Maverick.Api do
  @moduledoc """
  Provides the entrypoint for configuring and managing the
  implementation of Maverick in an application by a single
  `use/2` macro that provides a supervision tree `start_link/1`
  and `child_spec/1` for adding Maverick as a child of the
  top-level application supervisor.

  The Api module implementing `use Maverick.Api`, when started,
  will orchestrate the start of the process that does the heavy
  lifting of compiling function routes into a callback Handler
  module at application boot and then handing off to the Elli
  webserver configured to route requests by way of that Handler module.

  ## `use Maverick.Api` options

    * `:otp_app` - The name of the application implementing Maverick
      as an atom (required).

  ## `Maverick.Api` child_spec and start_link options

    * `:init_name` - The name the Initializer should register as.
      Primarily for logging and debugging, as the process should exit
      immediately with a `:normal` status if successful. May be any
      valid GenServer name.

    * `:supervisor_name` - The name the Maverick supervisor process
      should register as. May be any valid GenServer name.

    * `:name` - The name the Elli server process should register as.
      May be any valid GenServer name.

    * `:port` - The port number the webserver will listen on. Defaults
      to 4000.

    * `:tls_certfile` - The path to the PEM-encoded SSL/TLS certificate
      file to encrypt requests and responses.

    * `:tls_keyfile` - The path to the PEM-encoded SSL/TLS key file to
      encrypt requests and responses.
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @otp_app Keyword.fetch!(opts, :otp_app)
      @root_scope opts |> Keyword.get(:root_scope, "/")

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        Maverick.Api.Supervisor.start_link(__MODULE__, opts)
      end

      def list_routes() do
        @otp_app
        |> :application.get_key(:modules)
        |> filter_router_modules()
        |> collect_route_info()
        |> prepend_root_scope(@root_scope)
      end

      defp filter_router_modules({:ok, modules}) do
        Enum.filter(modules, fn module ->
          module
          |> to_string()
          |> String.ends_with?(".Maverick.Router")
        end)
      end

      defp collect_route_info(modules) do
        Enum.reduce(modules, [], fn module, acc ->
          acc ++ apply(module, :routes, [])
        end)
      end

      defp prepend_root_scope(routes, root_scope) do
        root_path = Maverick.Path.parse(root_scope)

        root_raw_path =
          case root_scope do
            "/" -> ""
            _ -> Maverick.Path.validate(root_scope)
          end

        Enum.map(routes, fn %Maverick.Route{path: path, raw_path: raw_path} = route ->
          %Maverick.Route{
            route
            | path: root_path ++ path,
              raw_path: root_raw_path <> raw_path
          }
        end)
      end
    end
  end
end

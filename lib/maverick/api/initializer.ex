defmodule Maverick.Api.Initializer do
  @moduledoc false

  # The Initializer implements a GenServer that reads and constructs the
  # webserver callback Handler module based on the route information exported
  # at compile time. It constructs a module named by concatenating the name
  # of the implementing application's Api module (example: MyApp.Api) and Handler
  # which is passed to Elli's start_link as the value of the `:callback` config
  # (`callback: MyApp.Api.Handler`).
  #
  # The Initializer's only job is to call the function that constructs the AST
  # for the Handler module and writing it out before exiting with a `:normal` status.
  # The Handler module implements a simple `c:handle/2` for the Elli behaviour that
  # uses the request method and path to route the request to the correct `handle/3`
  # function which is generated for each annotated internal function with a `@route`
  # attribute. It also generates a fall-through `handle/3` and the `c:handle_event/3`
  # function required by the Elli behaviour.
  #
  # This module is not intended for direct consumption by the application
  # implementing Maverick and is instead accessed indirectly by the module that
  # implements `use Maverick.Api`.

  use GenServer, restart: :transient

  @doc """
  Starts the Initializer, passing a tuple containing the module implementing
  the `Maverick.Api`, the `:otp_app` for the application and any options.
  """
  def start_link({api, otp_app, opts}) do
    name = Keyword.get(opts, :init_name, Module.concat(api, Initializer))

    GenServer.start_link(__MODULE__, {api, otp_app}, name: name)
  end

  @impl true
  def init(opts) do
    case build_handler_module(opts) do
      :ok -> {:ok, nil, {:continue, :exit}}
      _ -> {:error, "Failed to initialize the handler"}
    end
  end

  @impl true
  def handle_continue(:exit, state) do
    {:stop, :normal, state}
  end

  defp build_handler_module({api, otp_app}) do
    contents =
      otp_app
      |> get_routes()
      |> api.server().router_contents()

    api
    |> Module.concat(Handler)
    |> Module.create(contents, Macro.Env.location(__ENV__))

    :ok
  end

  defp get_routes(app) do
    :application.get_key(app, :modules)
    |> filter_router_modules()
    |> collect_route_info()
  end

  defp filter_router_modules({:ok, modules}) do
    Enum.filter(modules, fn module ->
      module
      |> to_string
      |> String.ends_with?(".Maverick.Router")
    end)
  end

  defp collect_route_info(modules) do
    Enum.reduce(modules, [], fn module, acc ->
      acc ++ apply(module, :routes, [])
    end)
  end
end

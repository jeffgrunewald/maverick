defmodule Maverick.Api.Initializer do
  @moduledoc false

  use GenServer, restart: :transient

  def start_link({api, opts}) do
    name = Keyword.get(opts, :init_name, Module.concat(api, Initializer))
    app = Keyword.fetch!(opts, :otp_app)

    GenServer.start_link(__MODULE__, {api, app}, name: name)
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

  defp build_handler_module({api, app}) do
    handler_functions = generate_handler_functions(app)

    contents =
      quote location: :keep do
        @behaviour :elli_handler

        def handle(request, _args) do
          handle(:elli_request.method(request), :elli_request.path(request), request)
        end

        unquote(handler_functions)

        def handle_event(_event, _data, _args), do: :ok
      end

    api
    |> Module.concat(Handler)
    |> Module.create(contents, Macro.Env.location(__ENV__))

    :ok
  end

  defp generate_handler_functions(app) do
    contents =
      for %{function: function, method: method, path: path} <- get_routes(app) do
        req_var = Macro.var(:req, __MODULE__)
        quote do
          def handle(unquote(method), unquote(path), unquote(req_var)), do: unquote(function)
        end
      end

    quote bind_quoted: [contents: contents], do: contents
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

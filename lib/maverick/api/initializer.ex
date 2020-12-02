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
    handler_functions = generate_handler_functions(otp_app)

    contents =
      quote location: :keep do
        @behaviour :elli_handler

        require Logger

        @impl true
        def handle(request, _args) do
          handle(
            :elli_request.method(request) |> to_string(),
            :elli_request.path(request),
            request
          )
        end

        unquote(handler_functions)

        def handle(method, path, req) do
          Logger.info(fn -> "Unhandled request received : #{inspect(req)}" end)
          {404, [Maverick.Request.Util.content_type()], Jason.encode!("Not Found")}
        end

        @impl true
        def handle_event(_event, _data, _args), do: :ok
      end

    api
    |> Module.concat(Handler)
    |> Module.create(contents, Macro.Env.location(__ENV__))

    :ok
  end

  defp generate_handler_functions(app) do
    contents =
      for %{
            args: arg_type,
            function: function,
            method: method,
            module: module,
            path: path,
            success_code: success,
            error_code: error
          } <-
            get_routes(app) do
        req_var = Macro.var(:req, __MODULE__)
        path_var = variablize_path(path)
        path_var_map = path_var_map(path)

        quote location: :keep do
          alias Maverick.{Exception, Request}

          def handle(unquote(method), unquote(path_var), unquote(req_var)) do
            args =
              unquote(req_var)
              |> Request.new(unquote(path_var_map))
              |> Request.Util.args(unquote(arg_type))

            response =
              unquote(module)
              |> apply(unquote(function), [args])
              |> Request.Util.wrap_response(unquote(success), unquote(error))

            Logger.debug(fn -> "Handled request #{inspect(unquote(req_var))}" end)

            response
          rescue
            exception ->
              %{tag: tag, handler: {mod, func, args}} = Exception.fallback(exception)

              Logger.info(fn ->
                "#{inspect(exception)} encountered processing request #{inspect(unquote(req_var))}; falling back to #{
                  tag
                }"
              end)

              {
                Exception.error_code(exception),
                [Request.Util.content_type()],
                apply(mod, func, args)
              }
          end
        end
      end

    quote location: :keep, bind_quoted: [contents: contents], do: contents
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

  defp variablize_path(path) do
    Enum.map(path, fn element ->
      case element do
        {:variable, variable} ->
          variable
          |> String.to_atom()
          |> Macro.var(__MODULE__)

        _ ->
          element
      end
    end)
  end

  defp path_var_map(path) do
    entries =
      Enum.reduce(path, [], fn element, acc ->
        case element do
          {:variable, variable} ->
            value = variable |> String.to_atom() |> Macro.var(__MODULE__)
            [{variable, value} | acc]

          _ ->
            acc
        end
      end)

    {:%{}, [], entries}
  end
end

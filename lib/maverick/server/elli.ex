defmodule Maverick.Server.Elli do
  @behaviour Maverick.Server

  def child_spec(api, opts) do
    port = Keyword.get(opts, :port, 4000)
    handler = Module.concat(api, Handler)

    name =
      opts
      |> Keyword.get(:name, Module.concat(api, Webserver))
      |> format_name()

    standard_config = [port: port, callback: handler, name: name]

    ssl_config =
      opts
      |> Keyword.take([:tls_certfile, :tls_keyfile])
      |> format_ssl_config()

    %{
      id: :elli,
      start: {:elli, :start_link, [Keyword.merge(standard_config, ssl_config)]}
    }
  end

  def router_contents(routes) do
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

      unquote(generate_handler_functions(routes))

      def handle(method, path, req) do
        Logger.info(fn -> "Unhandled request received : #{inspect(req)}" end)
        {404, [Maverick.Request.Util.content_type()], Jason.encode!("Not Found")}
      end

      @impl true
      def handle_event(_event, _data, _args), do: :ok
    end
  end

  defp generate_handler_functions(routes) do
      for %{
            args: arg_type,
            function: function,
            method: method,
            module: module,
            path: path,
            success_code: success,
            error_code: error
          } <-
            routes do
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
  end

  defp format_name({:via, _, _} = name), do: name
  defp format_name({:global, _} = name), do: name
  defp format_name(name) when is_atom(name), do: {:local, name}

  defp format_ssl_config(tls_certfile: certfile, tls_keyfile: keyfile),
    do: [ssl: true, certfile: certfile, keyfile: keyfile]

  defp format_ssl_config(_), do: []

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

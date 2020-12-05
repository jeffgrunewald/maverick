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

  defp format_name({:via, _, _} = name), do: name
  defp format_name({:global, _} = name), do: name
  defp format_name(name) when is_atom(name), do: {:local, name}

  defp format_ssl_config(tls_certfile: certfile, tls_keyfile: keyfile),
    do: [ssl: true, certfile: certfile, keyfile: keyfile]

  defp format_ssl_config(_), do: []
end

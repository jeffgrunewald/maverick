defmodule Maverick.Api.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(api, otp_app, opts) do
    name = Keyword.get(opts, :supervisor_name, Module.concat(api, Supervisor))

    Supervisor.start_link(__MODULE__, {api, otp_app, opts}, name: name)
  end

  @impl true
  def init({api, _otp_app, opts} = init_args) do
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

    children = [
      {Maverick.Api.Initializer, init_args},
      %{
        id: :elli,
        start: {:elli, :start_link, [Keyword.merge(standard_config, ssl_config)]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp format_name({:via, _, _} = name), do: name
  defp format_name({:global, _} = name), do: name
  defp format_name(name) when is_atom(name), do: {:local, name}

  defp format_ssl_config(tls_certfile: certfile, tls_keyfile: keyfile),
    do: [ssl: true, certfile: certfile, keyfile: keyfile]

  defp format_ssl_config(_), do: []
end

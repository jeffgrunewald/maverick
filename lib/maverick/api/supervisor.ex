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
    # name = Keyword.get(opts, :name, Module.concat(api, Webserver))

    children = [
      {Maverick.Api.Initializer, init_args},
      %{
        id: :elli,
        start: {:elli, :start_link, [[callback: handler, port: port]]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Maverick.Api.Supervisor do
  @moduledoc false

  # Implements the main Maverick supervisor that orchestrates
  # the lifecycle of the Maverick.Api.Initializer and the Elli
  # server process.
  #
  # Validates the configuration for the server, including port and
  # SSL/TLS configuration as well as any names under which to register
  # the three processes and ensures the Initializer is started first
  # to allow for creation of the Elli callback Handler module.
  #
  # This module is not intended for direct consumption by the
  # application implementing Maverick and is instead intended to be
  # called indirectly from the module implementing `use Maverick.Api`

  use Supervisor
  @server Maverick.Server.Elli

  @doc """
  Start the api supervisor, passing Api module, the `:otp_app` application
  name, and any options to configure the web server or the initializer.
  """
  def start_link(api, otp_app, opts) do
    name = Keyword.get(opts, :supervisor_name, Module.concat(api, Supervisor))

    Supervisor.start_link(__MODULE__, {api, otp_app, opts}, name: name)
  end

  @impl true
  def init({api, otp_app, opts}) do
    [
      {Maverick.Api.Initializer, {api, otp_app, opts}},
      @server.child_spec(api, opts)
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end

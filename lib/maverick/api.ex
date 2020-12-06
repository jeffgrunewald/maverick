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
      @server Keyword.get(opts, :server, Maverick.Server.Elli)

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        Maverick.Api.Supervisor.start_link(__MODULE__, @otp_app, opts)
      end

      def server(), do: @server
    end
  end
end

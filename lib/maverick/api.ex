defmodule Maverick.Api do
  @moduledoc false

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @otp_app Keyword.fetch!(opts, :otp_app)

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
    end
  end
end

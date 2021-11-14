defmodule SetupFinch do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      def finch_http1_client(_context), do: finch_client(:http1)
      def finch_http2_client(_context), do: finch_client(:http2)

      defp finch_client(protocol) do
        name = self() |> inspect() |> String.to_atom()

        opts = [
          name: name,
          pools: %{
            default: [
              size: 50,
              count: 1,
              protocol: protocol,
              conn_opts: [
                transport_opts: [
                  verify: :verify_peer,
                  cacertfile: Path.join(__DIR__, "../support/ca.pem")
                ]
              ]
            ]
          }
        ]

        start_supervised!({Finch, opts})
        [finch_client: name]
      end
    end
  end
end

defmodule SetupServer do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Plug.Conn

      def http_server(_context) do
        {:ok, server} =
          [
            plug: Maverick.TestApi,
            read_timeout: 1000,
            options: [port: 0, transport_options: [ip: :loopback]]
          ]
          |> Bandit.child_spec()
          |> start_supervised()

        {:ok, port} = ThousandIsland.local_port(server)
        [host: "http://localhost:#{port}", port: port]
      end

      def https_server(_context) do
        {:ok, server} =
          [
            plug: Maverick.TestApi,
            scheme: :https,
            read_timeout: 1000,
            options: [
              port: 0,
              transport_options: [
                ip: :loopback,
                certfile: Path.join(__DIR__, "../support/cert.pem"),
                keyfile: Path.join(__DIR__, "../support/key.pem")
              ]
            ]
          ]
          |> Bandit.child_spec()
          |> start_supervised()

        {:ok, port} = ThousandIsland.local_port(server)
        [host: "https://localhost:#{port}", port: port]
      end
    end
  end
end

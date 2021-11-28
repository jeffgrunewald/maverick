defmodule Maverick.ApiCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Maverick.Api.Helpers
    end
  end
end

defmodule Maverick.Api.Helpers do
  @moduledoc false

  import ExUnit.Callbacks, only: [start_supervised: 1, start_supervised!: 1]

  def http1_client(_context), do: finch_client(:http1)
  def http2_client(_context), do: finch_client(:http2)

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
    [client: name]
  end

  def http_server(_context), do: server(:http)
  def https_server(_context), do: server(:https)

  defp server(type) do
    transport_options =
      case type == :https do
        true ->
          [
            certfile: Path.join(__DIR__, "../support/cert.pem"),
            keyfile: Path.join(__DIR__, "../support/key.pem")
          ]

        false ->
          []
      end

    {:ok, server} =
      [
        plug: Maverick.TestApi,
        scheme: type,
        read_timeout: 1000,
        options: [port: 0, transport_options: Keyword.merge(transport_options, ip: :loopback)]
      ]
      |> Bandit.child_spec()
      |> start_supervised()

    {:ok, port} = ThousandIsland.local_port(server)
    [host: "#{type}://localhost:#{port}", port: port]
  end

  def req(client, method, uri, headers \\ [], body \\ nil) do
    method
    |> Finch.build(uri, headers, body)
    |> Finch.request(client)
  end

  def resp_code(%Finch.Response{status: status_code}), do: status_code

  def resp_headers(%Finch.Response{headers: headers}), do: headers

  def resp_body(%Finch.Response{body: body}), do: Jason.decode!(body)

  def resp_content_type(resp) do
    {"content-type", "application/json; charset=utf-8"} in resp_headers(resp)
  end
end

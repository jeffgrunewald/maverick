defmodule Maverick.Request do
  @moduledoc false

  import Record, only: [defrecordp: 2, extract: 2]

  defrecordp :req, extract(:req, from_lib: "elli/include/elli.hrl")

  defstruct [
    :body,
    :body_params,
    :headers,
    :host,
    :method,
    :params,
    :path,
    :path_params,
    :port,
    :query_params,
    :raw_path,
    :remote_ip,
    :scheme,
    :socket,
    :version
  ]

  def new(
        req(
          args: args,
          body: body,
          headers: headers,
          host: host,
          method: method,
          path: path,
          port: port,
          raw_path: raw_path,
          scheme: scheme,
          socket: socket,
          version: version
        ),
        path_params \\ %{}
      ) do
    body_params = body |> Jason.decode!()
    query_params = args |> Enum.into(%{})
    params = path_params |> Map.merge(query_parmas) |> Map.merge(body_params)

    %__MODULE__{
      body: body,
      body_params: body_params,
      headers: headers |> Enum.into(%{}),
      host: host,
      method: method |> to_string(),
      params: params,
      path: path,
      path_params: path_params,
      port: port,
      query_params: query_params,
      raw_path: raw_path,
      remote_ip: peer_ip(socket),
      scheme: scheme,
      socket: socket,
      version: version
    }
  end

  defp peer_ip(socket) do
    case :elli_tcp.peername(socket) do
      {:ok, {address, _port}} -> address
      {:error, _} -> :undefined
    end
  end
end

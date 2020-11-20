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

  def new(req(body: body) = request, path_params \\ %{}) do
    case decode_body(body) do
      {:ok, body_params} ->
        new(request, body_params, path_params)

      error ->
        error
    end
  end

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
        body_params,
        path_params
      ) do
    query_params = args |> Enum.into(%{})
    params = path_params |> Map.merge(query_params) |> Map.merge(body_params)

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

  defp decode_body(""), do: {:ok, %{}}

  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, json} when is_map(json) -> {:ok, json}
      {:ok, json} -> {:ok, %{"_json_body" => json}}
      {:error, %Jason.DecodeError{}} -> {:error, "Invalid request body"}
    end
  end

  defp peer_ip(socket) do
    case :elli_tcp.peername(socket) do
      {:ok, {address, _port}} -> address
      {:error, _} -> :undefined
    end
  end
end

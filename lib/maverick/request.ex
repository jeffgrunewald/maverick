defmodule Maverick.Request do
  @moduledoc """
  Defines the Maverick view of a web request as a struct and helper
  functions for constructing and handling it. Extracts the details from
  the Erlang record Elli uses to represent the request and adds or
  reformats various fields for working in Elixir.

  A request contains many of the raw values from the Elli record such as
  request body as binary or iolist data, the raw request path as a binary,
  http scheme as binary, and the port number, as well as derived values.

  The query parameters, path parameters, and headers are all converted to
  string-keyed maps and the request body is attempted to be decoded to a
  map from JSON. The decoded body, path params, and query params are all
  merged into a single `:params` map that is the default argument passed
  to internal functions unless otherwise noted in their decorator.

  A Maverick request struct has similarities between both Elli's request
  record and Plug's Conn struct, generally adhering closer to Elli's
  data structures (the version of HTTP as a 2-tuple of integers as opposed
  to a string) but with occasional tradeoffs for ease of compatibility
  with Elixir (representing the HTTP methods as strings instead of atoms
  for example).

  All parameters derived from user input are converted to string-keyed
  maps to prevent exhausting the BEAM's atom table.
  """

  import Record, only: [defrecordp: 2, extract: 2]

  defrecordp :req, extract(:req, from_lib: "elli/include/elli.hrl")

  @type http_method :: "OPTIONS" | "GET" | "HEAD" | "POST" | "PUT" | "DELETE" | "TRACE" | binary()

  @type t :: %__MODULE__{
          body: iodata(),
          body_params: %{optional(String.t()) => String.t()},
          headers: %{optional(String.t()) => String.t()},
          host: binary() | :undefined,
          method: http_method(),
          params: %{optional(String.t()) => String.t()},
          path: [binary()],
          path_params: %{optional(String.t()) => String.t()},
          port: 1..65535 | :undefined,
          query_params: %{optional(String.t()) => String.t()},
          raw_path: binary(),
          remote_ip: :inet.ipaddress(),
          scheme: binary() | :undefined,
          socket: {:plain, :inet.socket()} | {:ssl, :ssl.sslsocket()} | :undefined,
          version: {0, 9} | {1, 0} | {1, 1}
        }

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

  @doc """
  Creates a request struct from an Elli http request record
  and a map of path parameters drawn from variable elements
  in the route paths as keys and the values supplied in the
  request as the values.
  """
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
    body_params = decode_body(body)
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

  defp decode_body(""), do: %{}

  defp decode_body(body) do
    case Jason.decode!(body) do
      json when is_map(json) -> json
      json -> %{"_json_body" => json}
    end
  rescue
    exception in [Jason.DecodeError] ->
      raise Maverick.BadRequestError,
        message: "Invalid request body : #{Exception.message(exception)}"
  end

  defp peer_ip(socket) do
    case :elli_tcp.peername(socket) do
      {:ok, {address, _port}} -> address
      {:error, _} -> :undefined
    end
  end
end
